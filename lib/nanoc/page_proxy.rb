module Nanoc
  class PageProxy

    def initialize(page, params={})
      @page       = page
      @do_filter  = (params[:filter] != false)
    end

    def [](key)
      # Convert to a symbol and strip the ? if present
      real_key = key.to_s
      real_key = real_key[0..-2] if real_key.ends_with?('?')
      real_key = real_key.to_sym

      # Warn if necessary
      if Nanoc::Page::BUILTIN_KEYS.include?(real_key)
        $delayed_errors << "WARNING: the '#{real_key}' key is a built-in property and should\n" +
                           "         be accessed through the 'builtin' namespace -- this will be a hard\n" +
                           "         error in the future (page: #{@page.builtin_attribute_named(:path)})" unless $quiet
      end

      if real_key == :content and @do_filter
        @page.content
      elsif real_key == :file
        @page.file
      else
        if Nanoc::Page::BUILTIN_KEYS.include?(real_key)
          res = @page.builtin_attribute_named(real_key)
        else
          res = @page.custom_attribute_named(real_key)
        end

        if real_key == :builtin
          DotNotationHash.new(res, :is_builtin => true, :page => @page)
        else
          res.is_a?(Hash) ? DotNotationHash.new(res) : res
        end
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
