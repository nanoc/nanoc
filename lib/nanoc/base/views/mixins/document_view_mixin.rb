module Nanoc
  module DocumentViewMixin
    # @api private
    NONE = Object.new

    # @api private
    def initialize(document, context)
      super(context)
      @document = document
    end

    # @api private
    def unwrap
      @document
    end

    # @see Object#==
    def ==(other)
      other.respond_to?(:identifier) && identifier == other.identifier
    end
    alias_method :eql?, :==

    # @see Object#hash
    def hash
      self.class.hash ^ identifier.hash
    end

    # @return [Nanoc::Identifier]
    def identifier
      unwrap.identifier
    end

    # @see Hash#[]
    def [](key)
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap)

      unwrap.attributes[key]
    end

    # @return [Hash]
    def attributes
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap)

      unwrap.attributes
    end

    # @see Hash#fetch
    def fetch(key, fallback = NONE, &_block)
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap)

      if unwrap.attributes.key?(key)
        unwrap.attributes[key]
      else
        if !fallback.equal?(NONE)
          fallback
        elsif block_given?
          yield(key)
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
    end

    # @see Hash#key?
    def key?(key)
      Nanoc::Int::NotificationCenter.post(:visit_started, unwrap)
      Nanoc::Int::NotificationCenter.post(:visit_ended,   unwrap)

      unwrap.attributes.key?(key)
    end

    # @api private
    def reference
      unwrap.reference
    end

    # @api private
    def raw_content
      unwrap.content.string
    end
  end
end
