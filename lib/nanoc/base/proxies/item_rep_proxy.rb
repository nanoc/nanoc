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
      elsif real_key == :content
        @obj.content
      elsif real_key == :path
        @obj.web_path
      elsif real_key == :item
        @obj.item.to_proxy
      else
        super(key)
      end
    end

  end

end
