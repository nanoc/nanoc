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
        @obj.to_proxy
      elsif real_key == :mtime # backward compatibility
        @obj.page.mtime
      elsif real_key == :parent # backward compatibility
        @obj.page.parent.nil? ? nil : @obj.page.parent.to_proxy
      elsif real_key == :children # backward compatibility
        @obj.page.children.map { |page| page.to_proxy }
      else
        super(key)
      end
    end

  end

end
