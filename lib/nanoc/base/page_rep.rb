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

    # Returns the page representation content at the given stage.
    #
    # +stage+:: The stage at which the content should be fetched. Can be
    #           either +:pre+ or +:post+. To get the raw, uncompiled content,
    #           use Nanoc::Page#content.
    def content(stage = :pre, even_when_not_outdated = true)
      Nanoc::NotificationCenter.post(:visit_started, self)
      compile(even_when_not_outdated) unless @content[stage]
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      @content[stage]
    end

  end

end
