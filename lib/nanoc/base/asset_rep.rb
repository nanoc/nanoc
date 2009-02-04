module Nanoc

  class AssetRep < Nanoc::ItemRep

    alias_method :asset, :item

    def initialize(asset, attributes, name)
      super(asset, attributes, name)

      # Reset stages
      @filtered       = false
    end

    # Returns the type of this object.
    def type
      :asset_rep
    end

    # Returns the path to the output file as it would be used in a web
    # browser: starting with a slash (representing the web root), and only
    # including the filename and extension if they cannot be ignored (i.e.
    # they are not in the site configuration's list of index files).
    def web_path
      Nanoc::NotificationCenter.post(:visit_started, self)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      compile(false, false)

      @web_path ||= @item.site.router.web_path_for(self)
    end

    # Returns true if this asset rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Make super run a few checks
      return true if super

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime if !attribute_named(:skip_output)

      # Outdated if asset defaults outdated
      return true if @item.site.asset_defaults.mtime.nil?
      return true if !attribute_named(:skip_output) && @item.site.asset_defaults.mtime > compiled_mtime

      return false
    end

    # Returns the attribute with the given name. This method will look in
    # several places for the requested attribute:
    #
    # 1. This item representation's attributes;
    # 2. The attributes of this item representation's item;
    # 3. The item defaults' representation corresponding to this item
    #    representation;
    # 4. The item defaults in general;
    # 5. The hardcoded item defaults, if everything else fails.
    def attribute_named(name)
      super(name, @item.site.asset_defaults, Nanoc::Asset::DEFAULTS)
    end

    # Compiles the asset representation and writes the result to the disk.
    # This method should not be called directly; please use
    # Nanoc::Compiler#run instead, and pass this asset representation's asset
    # as its first argument.
    #
    # The asset representation will only be compiled if it wasn't compiled
    # before yet. To force recompilation of the asset rep, forgetting any
    # progress, set +from_scratch+ to true.
    #
    # +even_when_not_outdated+:: true if the asset rep should be compiled even
    #                            if it is not outdated, false if not.
    #
    # +from_scratch+:: true if the asset rep should be filtered again even if
    #                  it has already been filtered, false otherwise.
    def compile(even_when_not_outdated, from_scratch)
      # Don't compile if already compiled
      return if @compiled and !from_scratch

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
      @item.site.compiler.stack.push(self)
      Nanoc::NotificationCenter.post(:compilation_started, self)

      # Compile
      compile_textual unless @filtered
      @compiled = true

      # Stop
      @item.site.compiler.stack.pop
      Nanoc::NotificationCenter.post(:compilation_ended, self)
    end

  private

    # Compiles the asset rep, treating its contents as textual data.
    def compile_textual
      # Create raw and last snapshots if necessary
      # FIXME probably shouldn't belong here
      @content[:raw]  ||= @item.content
      @content[:last] ||= @content[:raw]

      # Run each filter
      attribute_named(:filters).each do |raw_filter|
        # Get filter arguments, if any
        if raw_filter.is_a?(String)
          filter_name = raw_filter
          filter_args = {}
        else
          filter_name = raw_filter['name']
          filter_args = raw_filter['args'] || {}
        end

        # Filter
        filter!(filter_name, filter_args)
      end

      # Write asset
      FileUtils.mkdir_p(File.dirname(self.disk_path))
      File.open(self.disk_path, 'w') { |io| io.write(@content[:last]) }
    end

  end

end
