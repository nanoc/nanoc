module Nanoc

  # Nanoc::PageDefaults represent the default attributes for all pages in the
  # site. If a specific page attribute is requested, but not found, then the
  # page defaults will be queried for this attribute. (If the attribute
  # doesn't even exist in the page defaults, hardcoded defaults will be used.)
  class PageDefaults

    # Nanoc::Site this set of page defaults belongs to.
    attr_accessor :site

    # A hash containing the default page attributes.
    attr_reader :attributes

    # The time when this set of page defaults was last modified.
    attr_reader :mtime

    # Creates a new set of page defaults.
    #
    # +attributes+:: The hash containing the metadata that individual pages
    #                will override.
    #
    # +mtime+:: The time when the page
    #           defaults were last modified (optional).
    def initialize(attributes, mtime=nil)
      @attributes = attributes.clean
      @mtime      = mtime
    end

    # Saves the page defaults in the database, creating it if it doesn't exist
    # yet or updating it if it already exists. Tells the site's data source to
    # save the page defaults.
    def save
      @site.data_source.loading do
        @site.data_source.save_page_defaults(self)
      end
    end

  end

end
