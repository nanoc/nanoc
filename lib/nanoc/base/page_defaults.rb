module Nanoc

  # PageDefaults represent the default attributes for all pages in the site.
  # If a specific page attribute is requested, but not found, then the page
  # defaults will be queried for this attribute. (If the attribute doesn't
  # even exist in the page defaults, hardcoded defaults will be used.)
  class PageDefaults

    attr_accessor :site
    attr_reader   :attributes, :mtime

    # Creates a new set of page defaults. +attributes+ is the metadata that
    # individual pages will override. +mtime+ is the time when the page
    # defaults were last modified (optional).
    def initialize(attributes, mtime=nil)
      @attributes = attributes
      @mtime      = mtime
    end

  end

end
