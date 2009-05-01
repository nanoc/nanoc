module Nanoc3

  # Nanoc3::LayoutProxy is a proxy object for a layout (Nanoc3::Layout).
  class LayoutProxy < Proxy

    # Requests the layout attribute with the given key.
    def [](key)
      if key == :content
        @obj.content
      elsif key == :identifier
        @obj.identifier
      elsif key == :mtime
        @obj.mtime
      else
        super(key)
      end
    end

  end

end
