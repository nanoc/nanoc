module Nanoc3

  # Nanoc3::ItemProxy is a proxy object for a item (Nanoc3::Item).
  class ItemProxy < Proxy

    # Requests the item attribute with the given name. +key+ can be a string
    # or a symbol, and it can contain a trailing question mark (which will be
    # stripped).
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :mtime
        @obj.mtime
      elsif real_key == :parent
        @obj.parent.nil? ? nil : @obj.parent.to_proxy
      elsif real_key == :children
        @obj.children.map { |item| item.to_proxy }
      elsif real_key == :content # backward compatibility
        content
      elsif real_key == :path # backward compatibility
        @obj.reps.find { |r| r.name == :default }.path
      else
        super(key)
      end
    end

    # Returns the compiled item content at the given snapshot.
    def content(snapshot=:pre) # backward compatibility
      @obj.reps.find { |r| r.name == :default }.content_at_snapshot(snapshot)
    end

    # Returns the item representation with the given name.
    def reps(name)
      rep = @obj.reps.find { |r| r.name == name }
      rep.nil? ? nil : rep.to_proxy
    end

  end

end
