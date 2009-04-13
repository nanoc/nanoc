module Nanoc3

  # Nanoc3::Proxy is used when making data available to items and layouts. It
  # provides an easy way to access data without the risk of accidentally
  # calling destructive methods.
  class Proxy

    # Creates a proxy for the given object.
    def initialize(obj)
      @obj = obj
    end

    # Requests the attribute with the given name. +key+ can be a string or a
    # symbol, and it can contain a trailing question mark (which will be
    # stripped).
    def [](key)
      real_key = key.to_s.sub(/\?$/, '').to_sym

      @obj.attribute_named(real_key)
    end

    # Sets a given attribute. The use of setting an object's attributes is not
    # recommended but may be necessary in some cases.
    def []=(key, value)
      @obj.attributes[key.to_sym] = value
    end

    # Used for requesting attributes without accessing the proxy like a hash.
    def method_missing(method, *args)
      self[method]
    end

  end

end
