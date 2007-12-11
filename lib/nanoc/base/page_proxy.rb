module Nanoc
  class PageProxy

    def initialize(page)
      @page = page
    end

    def [](key)
      # Convert to a symbol and strip the ? if present
      real_key = key.to_s
      real_key = real_key[0..-2] if real_key[-1] == ??
      real_key = real_key.to_sym

      if real_key == :content
        @page.content
      elsif real_key == :parent
        @page.parent.nil? ? nil : @page.parent.to_proxy
      elsif real_key == :children
        @page.children.map { |page| page.to_proxy }
      else
        @page.attribute_named(real_key)
      end
    end

    def []=(key, value)
      @page.attributes[key.to_sym] = value
    end

    def method_missing(method, *args)
      self[method]
    end

  end
end
