module Nanoc3

  # Nanoc3::ItemProxy is a proxy object for a item (Nanoc3::Item).
  class ItemProxy < Proxy

    # Requests the item attribute with the given key.
    def [](key)
      if key == :mtime
        @obj.mtime
      elsif key == :parent
        @obj.parent.nil? ? nil : @obj.parent.to_proxy
      elsif key == :children
        @obj.children.map { |item| item.to_proxy }
      elsif key == :content # backward compatibility
        content
      elsif key == :path # backward compatibility
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
