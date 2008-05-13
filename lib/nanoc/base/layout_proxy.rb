module Nanoc

  # Nanoc::LayoutProxy is a proxy object for a layout.
  class LayoutProxy < Proxy

    # Requests the attribute with the given name. +key+ can be a string or a
    # symbol, and it can contain a trailing question mark (which will be
    # stripped).
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

  end

end
