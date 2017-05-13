# frozen_string_literal: true

module Nanoc::Deploying::Deployers
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
  class Fog < ::Nanoc::Deploying::Deployer
    identifier :fog

    class FogWrapper
      def initialize(directory, is_dry_run)
        @directory = directory
        @is_dry_run = is_dry_run
      end

      def upload(source_filename, destination_key)
        log_effectful("uploading #{source_filename} -> #{destination_key}")

        unless dry_run?
          # FIXME: source_filename file is never closed
          @directory.files.create(
            key: destination_key,
            body: File.open(source_filename),
            public: true,
          )
        end
      end

      def remove(keys)
        keys.each do |key|
          log_effectful("removing #{key}")

          unless dry_run?
            @directory.files.get(key).destroy
          end
        end
      end

      def invalidate(keys, cdn, distribution)
        keys.each_slice(1000) do |keys_slice|
          keys_slice.each do |key|
            log_effectful("invalidating #{key}")
          end

          unless dry_run?
            cdn.post_invalidation(distribution, keys_slice)
          end
        end
      end

      def dry_run?
        @is_dry_run
      end

      def log_effectful(s)
        if @is_dry_run
          puts "[dry run] #{s}"
        else
          puts s
        end
      end
    end

    # @see Nanoc::Deploying::Deployer#run
    def run
      require 'fog'

      src      = File.expand_path(source_path)
      bucket   = config[:bucket] || config[:bucket_name]
      path     = config[:path]
      cdn_id   = config[:cdn_id]

      if path && path.end_with?('/')
        raise "The path `#{path}` is not supposed to have a trailing slash"
      end

      connection = connect
      directory = get_or_create_bucket(connection, bucket, path)
      wrapper = FogWrapper.new(directory, dry_run?)

      remote_files = list_remote_files(directory)
      etags = read_etags(remote_files)

      modified_keys, retained_keys = upload_all(src, path, etags, wrapper)

      removed_keys = remote_files.map(&:key) - retained_keys - modified_keys
      wrapper.remove(removed_keys)

      if cdn_id
        cdn = ::Fog::CDN.new(config_for_fog)
        distribution = cdn.get_distribution(cdn_id)
        wrapper.invalidate(modified_keys + removed_keys, cdn, distribution)
      end
    end

    private

    def config_for_fog
      config.dup.tap do |c|
        c.delete(:bucket)
        c.delete(:bucket_name)
        c.delete(:path)
        c.delete(:cdn_id)
        c.delete(:kind)
      end
    end

    def connect
      ::Fog::Storage.new(config_for_fog)
    end

    def get_or_create_bucket(connection, bucket, path)
      directory =
        begin
          connection.directories.get(bucket, prefix: path)
        rescue ::Excon::Errors::NotFound
          nil
        end

      if directory
        directory
      elsif dry_run?
        puts '[dry run] creating bucket'
      else
        puts 'creating bucket'
        connection.directories.create(key: bucket, prefix: path)
      end
    end

    def remote_key_for_local_filename(local_filename, src, path)
      relative_local_filename = local_filename.sub(/\A#{src}\//, '')

      if path
        File.join(path, relative_local_filename)
      else
        relative_local_filename
      end
    end

    def list_remote_files(directory)
      if directory
        [].tap do |files|
          directory.files.each { |file| files << file }
        end
      else
        []
      end
    end

    def list_local_files(src)
      Dir[src + '/**/*'].select { |f| File.file?(f) }
    end

    def upload_all(src, path, etags, wrapper)
      modified_keys = []
      retained_keys = []

      local_files = list_local_files(src)
      local_files.each do |file_path|
        key = remote_key_for_local_filename(file_path, src, path)
        if needs_upload?(key, file_path, etags)
          wrapper.upload(file_path, key)
          modified_keys.push(key)
        else
          retained_keys.push(key)
        end
      end

      [modified_keys, retained_keys]
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
  end
end
