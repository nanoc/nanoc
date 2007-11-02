module Nanoc

  class PageProxy

    def initialize(page, params={})
      @page       = page
      @do_filter  = (params[:filter] != false)
    end

    def [](key)
      if key.to_sym == :content and @do_filter
        @page.content
      elsif key.to_sym == :file
        @page.file
      elsif key.to_s.ends_with?('?')
        res = @page.attributes[key.to_s[0..-2].to_sym]
        res.is_a?(Hash) ? DotNotationHash.new(res) : res
      else
        res = @page.attributes[key]
        res.is_a?(Hash) ? DotNotationHash.new(res) : res
      end
    end

    def []=(key, value)
      @page.attributes[key.to_sym] = value
    end

    def method_missing(method, *args)
      self[method]
    end

  end

  class DotNotationHash

    def initialize(hash)
      @hash = hash
    end

    def [](key)
      res = @hash[key.to_sym]
      res.is_a?(Hash) ? DotNotationHash.new(res) : res
    end

    def method_missing(method, *args)
      self[method.to_sym]
    end

  end

end
