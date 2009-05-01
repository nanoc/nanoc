module Nanoc3

  # Nanoc3::ItemRepProxy is a proxy object for an item representation.
  class ItemRepProxy < Proxy

    # Requests the item representation attribute with the given key.
    def [](key)
      if key == :name
        @obj.name
      elsif key == :path
        @obj.path
      elsif key == :content # backward compatibility
        content
      elsif key == :item
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
