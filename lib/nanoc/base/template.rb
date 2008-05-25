module Nanoc

  # A Nanoc::Template represents a template, which can be used for creating
  # new pages (but pages don't need to be generated off pages).
  class Template

    # The Nanoc::Site this template belongs to.
    attr_accessor :site

    # The name of this template.
    attr_reader :name

    # The raw content a page created using this template will have.
    attr_reader :page_content

    # A hash containing the attributes a page created using this template will
    # have.
    attr_reader :page_attributes

    # Creates a new template.
    #
    # +name+:: The name of this template.
    #
    # +page_content+:: The raw content a page created using this template will
    #                  have.
    #
    # +page_attributes+:: A hash containing the attributes a page created
    #                     using this template will have.
    def initialize(page_content, page_attributes, name)
      @page_content     = page_content
      @page_attributes  = page_attributes.clean
      @name             = name
    end

    def [](key) # :nodoc:
      # FIXME get a decent warning
      warn "NOOO"

      case key
      when :name
        @name
      when :content
        @page_content
      when :meta
        YAML.dump(@page_attributes)
      when :extension
        '.txt'
      end
    end

  end

end
