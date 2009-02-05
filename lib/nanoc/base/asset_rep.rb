module Nanoc

  class AssetRep < Nanoc::ItemRep

    # For compatibility
    alias_method :asset, :item

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

      compile(false)

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

    # Returns the processing instructions for this asset representation.
    def processing_instructions
      instructions = []

      # Add filters
      attribute_named(:filters).each do |raw_filter|
        # Get filter name and arguments
        if raw_filter.is_a?(String)
          filter_name = raw_filter
          filter_args = {}
        else
          filter_name = raw_filter['name']
          filter_args = raw_filter['args'] || {}
        end

        # Add to instructions
        instructions << [ :filter, filter_name, filter_args ]
      end

      # Add write
      instructions << [ :write ]

      instructions
    end

  end

end
