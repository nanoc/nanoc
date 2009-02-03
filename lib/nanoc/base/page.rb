module Nanoc

  # A Nanoc::Page represents a page in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation.
  #
  # A page is observable. The following events will be notified:
  #
  # * :visit_started
  # * :visit_ended
  #
  # Each page has a list of page representations or reps (Nanoc::PageRep);
  # compiling a page actually compiles all of its representations.
  class Page < Nanoc::Item

    # Default values for pages.
    DEFAULTS = {
      :custom_path  => nil,
      :extension    => 'html',
      :filename     => 'index',
      :filters_pre  => [],
      :filters_post => [],
      :layout       => 'default',
      :skip_output  => false
    }

    # Builds the individual page representations (Nanoc::PageRep) for this
    # page.
    def build_reps
      super(PageRep, @site.page_defaults)
    end

    # Returns the type of this object.
    def type
      :page
    end

    # Returns a proxy (Nanoc::PageProxy) for this page.
    def to_proxy
      super(PageProxy)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      Nanoc::NotificationCenter.post(:visit_started, self)
      Nanoc::NotificationCenter.post(:visit_ended,   self)

      super(name, @site ? @site.page_defaults : nil, Nanoc::Page::DEFAULTS)
    end

  end

end
