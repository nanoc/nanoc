module Nanoc

  # Nanoc::PageProxy is a proxy object for a page (Nanoc::Page).
  class PageProxy < Proxy

    # Requests the page attribute with the given name. +key+ can be a string
    # or a symbol, and it can contain a trailing question mark (which will be
    # stripped).
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :mtime
        @obj.mtime
      elsif real_key == :parent
        @obj.parent.nil? ? nil : @obj.parent.to_proxy
      elsif real_key == :children
        @obj.children.map { |page| page.to_proxy }
      elsif real_key == :content # backward compatibility
        content
      elsif real_key == :path # backward compatibility
        @obj.reps.find { |r| r.name == :default }.web_path
      else
        super(key)
      end
    end

    # Returns the compiled page content at the given snapshot.
    def content(snapshot=:pre) # backward compatibility
      @obj.reps.find { |r| r.name == :default }.content(snapshot)
    end

    # Returns the page representation with the given name.
    def reps(name)
      rep = @obj.reps.find { |r| r.name == name }
      rep.nil? ? nil : rep.to_proxy
    end

  end

end
