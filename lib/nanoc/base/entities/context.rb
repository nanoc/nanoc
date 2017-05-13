# frozen_string_literal: true

module Nanoc::Int
  # Provides a context and a binding for use in filters such as the ERB and
  # Haml ones.
  #
  # @api private
  class Context
    # Creates a new context based off the contents of the hash.
    #
    # Each pair in the hash will be converted to an instance variable and an
    # instance method. For example, passing the hash `{ :foo => 'bar' }` will
    # cause `@foo` to have the value `"bar"`, and the instance method `#foo`
    # to return the same value `"bar"`.
    #
    # @param [Hash] hash A list of key-value pairs to make available
    #
    # @example Defining a context and accessing values
    #
    #     context = Nanoc::Int::Context.new(
    #       :name     => 'Max Payne',
    #       :location => 'in a cheap motel'
    #     )
    #     context.instance_eval do
    #       "I am #{name} and I am hiding #{@location}."
    #     end
    #     # => "I am Max Payne and I am hiding in a cheap motel."
    def initialize(hash)
      hash.each_pair do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end

    # Returns a binding for this instance.
    #
    # @return [Binding] A binding for this instance
    # rubocop:disable Style/AccessorMethodName
    def get_binding
      binding
    end
    # rubocop:enable Style/AccessorMethodName

    def method_missing(method, *args, &blk)
      ivar_name = '@' + method.to_s
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      else
        super
      end
    end

    def respond_to_missing?(method, include_all)
      ivar_name = '@' + method.to_s
      instance_variable_defined?(ivar_name) || super
    end

    def include(mod)
      metaclass = class << self; self; end
      metaclass.instance_eval { include(mod) }
    end
  end
end
