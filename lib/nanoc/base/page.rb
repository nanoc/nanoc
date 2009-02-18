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

    # Returns the type of this object.
    def type
      :page
    end

  end

end
