module Nanoc

  # Nanoc::PageProxy is a proxy object for a Nanoc::Page object.
  class PageProxy < Proxy

    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :content
        @obj.content
      elsif real_key == :path
        @obj.path
      elsif real_key == :parent
        @obj.parent.nil? ? nil : @obj.parent.to_proxy
      elsif real_key == :children
        @obj.children.map { |page| page.to_proxy }
      else
        super(key)
      end
    end

  end

end
