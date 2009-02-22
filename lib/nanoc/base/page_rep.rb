module Nanoc

  class PageRep < Nanoc::ItemRep

    # For compatibility
    alias_method :page, :item

    # Returns the type of this object.
    def type
      :page_rep
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

  end

end
