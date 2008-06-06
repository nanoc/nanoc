module Nanoc

  # TODO document
  class PageRepProxy < Proxy

    # TODO document
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :content
        @obj.content
      elsif real_key == :path
        @obj.web_path
      elsif real_key == :page
        @obj.page.to_proxy
      else
        super(key)
      end
    end

  end

end
