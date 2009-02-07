module Nanoc

  class PageRep < Nanoc::ItemRep

    # For compatibility
    alias_method :page, :item

    # Returns the type of this object.
    def type
      :page_rep
    end

    # Returns true if this page rep's output file is outdated and must be
    # regenerated, false otherwise.
    def outdated?
      # Make super run a few checks
      return true if super

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime if !attribute_named(:skip_output)

      # Outdated if page defaults outdated
      return true if @item.site.page_defaults.mtime.nil?
      return true if !attribute_named(:skip_output) && @item.site.page_defaults.mtime > compiled_mtime

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
      super(name, @item.site.page_defaults, Nanoc::Page::DEFAULTS)
    end

    # Returns the page representation content in the given snapshot.
    #
    # +snapshot+:: The snapshot from which the content should be fetched. To
    #              get the raw, uncompiled content, use +:raw+.
    def content_at_snapshot(snapshot = :pre)
      Nanoc::NotificationCenter.post(:visit_started, self)
      @item.site.compiler.compile_rep(self, false) unless @content[snapshot]
      Nanoc::NotificationCenter.post(:visit_ended, self)

      @content[snapshot]
    end

    # Returns the processing instructions for this asset representation.
    def processing_instructions
      instructions = []

      # Add pre filters
      attribute_named(:filters_pre).each do |raw_filter|
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
      instructions << [ :snapshot, :pre ]

      # Add layout
      instructions << [ :layout, attribute_named(:layout) ] unless attribute_named(:layout).nil?

      # Add post filters
      attribute_named(:filters_post).each do |raw_filter|
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
      instructions << [ :snapshot, :post ]

      # Add write
      instructions << [ :write ]

      instructions
    end

  end

end
