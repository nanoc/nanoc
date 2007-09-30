module Nanoc

  class PageProxy
    def initialize(page, params={})
      @page       = page
      @do_filter  = (params[:filter] != false)
    end

    def [](key)
      if key.to_sym == :content and @do_filter
        @page.content
      else
        if key.to_s.starts_with?('_')
          nil
        elsif key.to_s.ends_with?('?')
          @page.attributes[key.to_s[0..-2].to_sym]
        else
          @page.attributes[key]
        end
      end
    end

    def method_missing(method, *args)
      self[method]
    end
  end

end
