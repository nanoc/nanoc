module Nanoc::Extra::Deployers
  # A deployer that deploys a site using [fog](https://github.com/geemus/fog).
  #
  # @example A deployment configuration with public and staging configurations
  #
  #   deploy:
  #     public:
  #       kind:       fog
  #       bucket:     nanoc-site
  #       cdn_id:     XXXXXX
  #     preprod:
  #       kind:       fog
  #       provider:   local
  #       local_root: ~/myCloud
  #       bucket:     nanoc-site
  #     staging:
  #       kind:       fog
  #       provider:   local
  #       local_root: ~/myCloud
  #       bucket:     nanoc-site-staging
  #
  # @api private
  class Fog < ::Nanoc::Extra::Deployer
    # @see Nanoc::Extra::Deployer#run
    def run
      require 'fog'

      # Get params, unsetting anything we don't want to pass through to fog.
      src      = File.expand_path(source_path)
      bucket   = config.delete(:bucket) || config.delete(:bucket_name)
      path     = config.delete(:path)
      cdn_id   = config.delete(:cdn_id)

      config.delete(:kind)

      # Validate params
      error 'The path requires no trailing slash' if path && path[-1, 1] == '/'

      # Mock if necessary
      if self.dry_run?
        puts 'Dry run - simulation'
        ::Fog.mock!
      end

      # Get connection
      puts 'Connecting'
      connection = ::Fog::Storage.new(config)

      # Get bucket
      puts 'Getting bucket'
      begin
        directory = connection.directories.get(bucket, prefix: path)
      rescue ::Excon::Errors::NotFound
        should_create_bucket = true
      end
      should_create_bucket = true if directory.nil?

      # Create bucket if necessary
      if should_create_bucket
        puts 'Creating bucket'
        directory = connection.directories.create(key: bucket, prefix: path)
      end

      # Get list of remote files
      files = directory.files
      truncated = files.respond_to?(:is_truncated) && files.is_truncated
      while truncated
        set = directory.files.all(marker: files.last.key)
        truncated = set.is_truncated
        files += set
      end
      keys_to_destroy = files.map(&:key)
      keys_to_invalidate = []
      etags = read_etags(files)

      # Upload all the files in the output folder to the clouds
      puts 'Uploading local files'
      FileUtils.cd(src) do
        files = Dir['**/*'].select { |f| File.file?(f) }
        files.each do |file_path|
          key = path ? File.join(path, file_path) : file_path
          upload(key, file_path, etags, keys_to_destroy, keys_to_invalidate, directory)
        end
      end

      # delete extraneous remote files
      puts 'Removing remote files'
      keys_to_destroy.each do |key|
        directory.files.get(key).destroy
      end

      # invalidate CDN objects
      if cdn_id
        puts 'Invalidating CDN distribution'
        keys_to_invalidate.concat(keys_to_destroy)
        cdn = ::Fog::CDN.new(config)
        # fog cannot mock CDN requests
        unless self.dry_run?
          distribution = cdn.get_distribution(cdn_id)
          # usual limit per invalidation: 1000 objects
          keys_to_invalidate.each_slice(1000) do |paths|
            cdn.post_invalidation(distribution, paths)
          end
        end
      end

      puts 'Done!'
    end

    private

    def upload(key, file_path, etags, keys_to_destroy, keys_to_invalidate, dir)
      keys_to_destroy.delete(key)

      return unless needs_upload?(key, file_path, etags)

      dir.files.create(
        key: key,
        body: File.open(file_path),
        public: true)
      keys_to_invalidate.push(key)
    end

    def needs_upload?(key, file_path, etags)
      remote_etag = etags[key]
      return true if remote_etag.nil?

      local_etag = calc_local_etag(file_path)
      remote_etag != local_etag
    end

    def read_etags(files)
      case config[:provider]
      when 'aws'
        files.each_with_object({}) do |file, etags|
          etags[file.key] = file.etag
        end
      else
        {}
      end
    end

    def calc_local_etag(file_path)
      case config[:provider]
      when 'aws'
        Digest::MD5.file(file_path).hexdigest
      end
    end

    # Prints the given message on stderr and exits.
    def error(msg)
      raise RuntimeError.new(msg)
    end
  end
end
