module Nanoc

  # TODO document
  class Template

    attr_accessor :site
    attr_reader   :name, :page_content, :page_attributes

    # TODO document
    def initialize(name, page_content, page_attributes)
      @name             = name
      @page_content     = page_content
      @page_attributes  = page_attributes
    end

    # :nodoc:
    def [](key)
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
