module Nanoc

  # Nanoc::AssetProxy is a proxy object for an asset (Nanoc::Asset).
  class AssetProxy < Proxy

    # Requests the page attribute with the given name. +key+ can be a string
    # or a symbol, and it can contain a trailing question mark (which will be
    # stripped).
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      if real_key == :mtime
        @obj.mtime
      elsif real_key == :path # backward compatibility
        @obj.reps.find { |r| r.name == :default }.web_path
      else
        super(key)
      end
    end

    # Returns the asset representation with the given name.
    def reps(name)
      rep = @obj.reps.find { |r| r.name == name }
      rep.nil? ? nil : rep.to_proxy
    end

  end

end
