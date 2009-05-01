module Nanoc3

  # Nanoc3::Proxy is used when making data available to items and layouts. It
  # provides an easy way to access data without the risk of accidentally
  # calling destructive methods.
  class Proxy

    # Creates a proxy for the given object.
    def initialize(obj)
      @obj = obj
    end

    # Requests the attribute with the given key.
    def [](key)
      @obj[key]
    end

    # Sets a given attribute. The use of setting an object's attributes is not
    # recommended but may be necessary in some cases.
    def []=(key, value)
      @obj[key] = value
    end

    # Used for requesting attributes without accessing the proxy like a hash.
    def method_missing(method, *args)
      self[method.to_sym]
    end

  end

end
