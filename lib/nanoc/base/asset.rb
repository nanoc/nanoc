module Nanoc

  class Asset

    DEFAULTS = {
      :extension  => 'dat',
      :filters    => []
    }

    # The Nanoc::Site this asset belongs to.
    attr_accessor :site

    # This assets's file.
    attr_reader   :file

    # A hash containing this asset's attributes.
    attr_accessor :attributes

    # This asset's path.
    attr_reader   :path

    # The time when this asset was last modified.
    attr_reader   :mtime

    def initialize(file, attributes, path, mtime=nil)
      # Set primary attributes
      @file           = file
      @attributes     = attributes.clean
      @path           = path.cleaned_path
      @mtime          = mtime

      # Compiled file is not present
      @compiled_file  = nil

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered       = false
      @written        = false
    end

    def to_proxy
      @proxy ||= AssetProxy.new(self)
    end

    def outdated?
      # Outdated if compiled file doesn't exist
      return true if !File.file?(disk_path)

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime

      # Outdated if file too old
      return true if @file.mtime > compiled_mtime

      # Outdated if dependencies outdated
      return true if @site.code.mtime and @site.code.mtime > compiled_mtime

      return false
    end

    def attribute_named(name)
      # Check in here
      return @attributes[name] if @attributes.has_key?(name)

      # TODO check in asset defaults

      # Check in hardcoded defaults
      return DEFAULTS[name]
    end

    # Returns the path to the output file, including the path to the output
    # directory specified in the site configuration, and including the
    # filename and extension.
    def disk_path
      @disk_path ||= @site.router.disk_path_for(self)
    end

    # Returns the path to the output file as it would be used in a web
    # browser: starting with a slash (representing the web root), and only
    # including the filename and extension if they cannot be ignored (i.e.
    # they are not in the site configuration's list of index files).
    def web_path
      @web_path ||= @site.router.web_path_for(self)
    end

    def compile
      # Get filters
      filters = attribute_named(:filters)

      # Run each filter
      current_file = @file
      filters.each do |filter_name|
        # Create filter
        klass = PluginManager.instance.binary_filter(filter_name.to_sym)
        raise Nanoc::Errors::UnknownFilterError.new(filter_name) if klass.nil?
        filter = klass.new(self.to_proxy, @site)

        # Run filter
        current_file = filter.run(current_file)
      end

      # Write asset
      FileUtils.cp(current_file.path, disk_path)
    end

  end

end
