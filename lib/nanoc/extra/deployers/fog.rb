# encoding: utf-8

module Nanoc::Extra::Deployers

  # A deployer that deploys a site using [fog](https://github.com/geemus/fog).
  #
  # @example A deployment configuration with public and staging configurations
  #
  #   deploy:
  #     public:
  #       kind:       fog
  #       provider:   local
  #       local_root: ~/myCloud
  #       bucket:     nanoc-site
  #     staging:
  #       kind:       fog
  #       provider:   local
  #       local_root: ~/myCloud
  #       bucket:     nanoc-site-staging
  class Fog < ::Nanoc::Extra::Deployer

    # @see Nanoc::Extra::Deployer#run
    def run
      require 'fog'

      # Get params
      src      = File.expand_path(self.source_path)
      bucket   = self.config.delete(:bucket) || self.config.delete(:bucket_name)
      path     = self.config[:path]

      self.config.delete(:kind)

      # Validate params
      error 'The path requires no trailing slash' if path && path[-1,1] == '/'

      # Mock if necessary
      if self.dry_run?
        ::Fog.mock!
      end

      # Get connection
      puts "Connecting"
      connection = ::Fog::Storage.new(self.config)

      # Get bucket
      puts "Getting bucket"
      begin
        directory = connection.directories.get(bucket)
      rescue ::Excon::Errors::NotFound
        should_create_bucket = true
      end
      should_create_bucket = true if directory.nil?

      # Create bucket if necessary
      if should_create_bucket
        directory = connection.directories.create(:key => bucket)
      end

      # Get list of remote files
      files = directory.files
      truncated = files.respond_to?(:is_truncated) && files.is_truncated
      while truncated
        set = directory.files.all(:marker => files.last.key)
        truncated = set.is_truncated
        files = files + set
      end

      # Delete all the files in the bucket
      puts "Removing remote files"
      files.all.each do |file|
        file.destroy
      end

      # Upload all the files in the output folder to the clouds
      puts "Uploading local files"
      FileUtils.cd(src) do
        files = Dir['**/*'].select { |f| File.file?(f) }
        files.each do |file_path|
          directory.files.create(
            :key => "#{path}#{file_path}",
            :body => File.open(file_path),
            :public => true)
        end
      end

      puts "Done!"
    end

  private

    # Prints the given message on stderr and exits.
    def error(msg)
      raise RuntimeError.new(msg)
    end

  end

end
