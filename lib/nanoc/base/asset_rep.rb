module Nanoc

  # A Nanoc::AssetRep is a single representation (rep) of an asset
  # (Nanoc::Asset). An asset can have multiple representations. A
  # representation has its own attributes and its own output file. A single
  # asset can therefore have multiple output files, each run through a
  # different set of filters with a different layout.
  #
  # An asset representation is observable. The following events will be
  # notified:
  #
  # * :compilation_started
  # * :compilation_ended
  # * :filtering_started
  # * :filtering_ended
  #
  # The compilation-related events have one parameters (the page
  # representation); the filtering-related events have two (the page
  # representation, and a symbol containing the filter class name).
  class AssetRep

    # The asset (Nanoc::Asset) to which this representation belongs.
    attr_reader   :asset

    # A hash containing this asset representation's attributes.
    attr_accessor :attributes

    # This asset representation's unique name.
    attr_reader   :name

    # Creates a new asset representation for the given asset and with the
    # given attributes.
    #
    # +asset+:: The asset (Nanoc::Asset) to which the new representation will
    #           belong.
    #
    # +attributes+:: A hash containing the new asset representation's
    #                attributes. This hash must have been run through
    #                Hash#clean before using it here.
    #
    # +name+:: The unique name for the new asset representation.
    def initialize(asset, attributes, name)
      # Set primary attributes
      @asset      = asset
      @attributes = attributes
      @name       = name

      # Reset flags
      @compiled   = false
      @modified   = false
      @created    = false

      # Reset stages
      @filtered   = false
    end

    # Returns a proxy (Nanoc::AssetRepProxy) for this asset representation.
    def to_proxy
      @proxy ||= AssetRepProxy.new(self)
    end

    # Returns true if this asset rep's output file was created during the last
    # compilation session, or false if the output file did already exist.
    def created?
      @created
    end

    # Returns true if this asset rep's output file was modified during the
    # last compilation session, or false if the output file wasn't changed.
    def modified?
      @modified
    end

    # Returns true if this page rep has been compiled, false otherwise.
    def compiled?
      @compiled
    end

    # Returns the path to the output file, including the path to the output
    # directory specified in the site configuration, and including the
    # filename and extension.
    def disk_path
      @disk_path ||= @asset.site.router.disk_path_for(self)
    end

    # Returns the path to the output file as it would be used in a web
    # browser: starting with a slash (representing the web root), and only
    # including the filename and extension if they cannot be ignored (i.e.
    # they are not in the site configuration's list of index files).
    def web_path
      @web_path ||= @asset.site.router.web_path_for(self)
    end

    # Returns true if this asset rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Outdated if we don't know
      return true if @asset.mtime.nil?

      # Outdated if compiled file doesn't exist
      return true if !File.file?(disk_path)

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime

      # Outdated if file too old
      return true if @asset.mtime > compiled_mtime

      # Outdated if asset defaults outdated
      return true if @asset.site.asset_defaults.mtime.nil?
      return true if @asset.site.asset_defaults.mtime > compiled_mtime

      # Outdated if code outdated
      return true if @asset.site.code.mtime.nil?
      return true if @asset.site.code.mtime > compiled_mtime

      return false
    end

    # Returns the attribute with the given name. This method will look in
    # several places for the requested attribute:
    #
    # 1. This asset representation's attributes;
    # 2. The attributes of this asset representation's asset (but only if this
    #    is the default representation);
    # 3. The asset defaults' representation corresponding to this asset
    #    representation;
    # 4. The asset defaults in general (but only if this is the default asset
    #    representation);
    # 5. The hardcoded asset defaults, if everything else fails.
    def attribute_named(name)
      # Check in here
      return @attributes[name] if @attributes.has_key?(name)

      # Check in asset
      if @name == :default
        return @asset.attributes[name] if @asset.attributes.has_key?(name)
      end

      # Check in asset defaults' asset rep
      asset_default_reps = @asset.site.asset_defaults.attributes[:reps] || {}
      asset_default_rep  = asset_default_reps[@name] || {}
      return asset_default_rep[name] if asset_default_rep.has_key?(name)

      # Check in site defaults (global)
      if @name == :default
        asset_defaults_attrs = @asset.site.asset_defaults.attributes
        return asset_defaults_attrs[name] if asset_defaults_attrs.has_key?(name)
      end

      # Check in hardcoded defaults
      return Nanoc::Asset::DEFAULTS[name]
    end

    # Compiles the asset representation and writes the result to the disk.
    # This method should not be called directly; please use
    # Nanoc::Compiler#run instead, and pass this asset representation's asset
    # as its first argument.
    #
    # +even_when_not_outdated+:: true if the asset rep should be compiled even
    #                            if it is not outdated, false if not.
    #
    # +from_scratch+:: true if the asset rep should be filtered again even if
    #                  it has already been filtered, false otherwise.
    def compile(even_when_not_outdated, from_scratch)
      # Skip unless outdated
      unless outdated? or even_when_not_outdated
        Nanoc::NotificationCenter.post(:compilation_started, self)
        Nanoc::NotificationCenter.post(:compilation_ended,   self)
        return
      end

      # Reset flags
      @compiled = false
      @modified = false
      @created  = !File.file?(self.disk_path)

      # Forget progress if requested
      @filtered = false if from_scratch

      # Start
      @asset.site.compiler.stack.push(self)
      Nanoc::NotificationCenter.post(:compilation_started, self)

      # Compile
      unless @filtered
        if attribute_named(:binary) == true
          compile_binary
        else
          compile_textual
        end
      end
      @compiled = true

      # Stop
      @asset.site.compiler.stack.pop
      Nanoc::NotificationCenter.post(:compilation_ended, self)
    end

  private

    # Computes and returns the MD5 digest for the given file.
    def digest(file)
      # Create hash
      incr_digest = Digest::MD5.new()

      # Collect data
      file.rewind
      incr_digest << file.read(1000) until file.eof?

      # Calculate hex hash
      incr_digest.hexdigest
    end

    # Compiles the asset rep, treating its contents as binary data.
    def compile_binary
      # Get filters
      filters = attribute_named(:filters)

      # Calculate digest before
      digest_before = File.file?(disk_path) ? digest(File.open(disk_path, 'r')) : nil

      # Run each filter
      current_file = @asset.file
      filters.each do |filter_name|
        # Create filter
        klass = Nanoc::BinaryFilter.named(filter_name)
        raise Nanoc::Errors::UnknownFilterError.new(filter_name) if klass.nil?
        filter = klass.new(self.to_proxy, @asset.to_proxy, @asset.site)

        # Run filter
        Nanoc::NotificationCenter.post(:filtering_started, self, klass.identifier)
        current_file = filter.run(current_file)
        Nanoc::NotificationCenter.post(:filtering_ended,   self, klass.identifier)
      end

      # Write asset
      FileUtils.mkdir_p(File.dirname(self.disk_path))
      FileUtils.cp(current_file.path, disk_path)

      # Calculate digest after
      digest_after = digest(current_file)
      @modified = (digest_after != digest_before)
    end

    # Compiles the asset rep, treating its contents as textual data.
    def compile_textual
      # Get filters
      filters = attribute_named(:filters)

      # Prepare
      current_content = @asset.file.read

      # Check modified
      @modified = @created ? true : File.read(self.disk_path) != current_content

      # Run each filter
      filters.each do |filter_name|
        # Create filter
        klass = Nanoc::Filter.named(filter_name)
        raise Nanoc::Errors::UnknownFilterError.new(filter_name) if klass.nil?
        filter = klass.new(self)

        # Run filter
        Nanoc::NotificationCenter.post(:filtering_started, self, klass.identifier)
        current_content = filter.run(current_content)
        Nanoc::NotificationCenter.post(:filtering_ended,   self, klass.identifier)
      end

      # Write asset
      FileUtils.mkdir_p(File.dirname(self.disk_path))
      File.open(self.disk_path, 'w') { |io| io.write(current_content) }
    end

  end

end
