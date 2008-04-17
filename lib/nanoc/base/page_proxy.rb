module Nanoc

  # Nanoc::PageProxy is a proxy object for a Nanoc::Page object, used when
  # running filters and layout processors.
  class PageProxy

    instance_methods.each { |m| undef_method m unless m =~ /^__/ }

    # Creates a page proxy for the given page.
    def initialize(page)
      @page = page
    end

    # Requests the attribute with the given name. +key+ can be a string or a
    # symbol, and it can contain a trailing question mark (which will be
    # stripped).
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :content
        @page.content
      elsif real_key == :path
        @page.path
      elsif real_key == :parent
        @page.parent.nil? ? nil : @page.parent.to_proxy
      elsif real_key == :children
        @page.children.map { |page| page.to_proxy }
      else
        @page.attribute_named(real_key)
      end
    end

    # Sets a given attribute. The use of setting a page's attributes is not
    # recommended but may be necessary in some cases.
    def []=(key, value)
      @page.attributes[key.to_sym] = value
    end

    # Used for requesting attributes without accessing the page proxy like a
    # hash.
    def method_missing(method, *args)
      self[method]
    end

  end

end
