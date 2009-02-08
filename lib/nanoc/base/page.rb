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

    # Builds the individual page representations (Nanoc::PageRep) for this
    # page.
    def build_reps
      super(PageRep)
    end

    # Returns the type of this object.
    def type
      :page
    end

    # Returns a proxy (Nanoc::PageProxy) for this page.
    def to_proxy
      super(PageProxy)
    end

  end

end
