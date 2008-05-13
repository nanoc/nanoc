module Nanoc

  # TODO document
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

    def outdated?
      # Outdated if we don't know
      return true if @mtime.nil?

      # Check if there are newer pages
      @site.pages.any? { |p| !p.mtime.nil? and @mtime > p.mtime }
    end

  end

end
