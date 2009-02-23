module Nanoc

  # Nanoc::ItemRepProxy is a proxy object for an item representation.
  class ItemRepProxy < Proxy

    # Requests the item representation attribute with the given name. +key+
    # can be a string or a symbol, and it can contain a trailing question mark
    # (which will be stripped).
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :name
        @obj.name
      elsif real_key == :path
        @obj.path
      elsif real_key == :content # backward compatibility
        content
      elsif real_key == :item
        @obj.item.to_proxy
      else
        super(key)
      end
    end

    # Returns the compiled iten rep content at the given snapshot.
    def content(snapshot=:pre) # backward compatibility
      @obj.content_at_snapshot(snapshot)
    end

  end

end
