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
        @obj.reps[:default].content
      elsif real_key == :path # backward compatibility
        @obj.reps[:default].web_path
      else
        super(key)
      end
    end

    # TODO document
    def reps(name)
      rep = @obj.reps[name]
      rep.nil? ? nil : rep.to_proxy
    end

  end

end
