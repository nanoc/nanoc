module Nanoc

  # Nanoc::LayoutProxy is a proxy object for a layout.
  class LayoutProxy < Proxy

    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :content
        @obj.content
      elsif real_key == :path
        @obj.path
      else
        super(key)
      end
    end

    def to_s
      ':D'
    end

  end

end
