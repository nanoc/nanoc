# encoding: utf-8

module Nanoc

  # Provides a context and a binding for use in filters such as the ERB and
  # Haml ones.
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
    #     context = Nanoc::Context.new(
    #       :name     => 'Max Payne',
    #       :location => 'in a cheap motel'
    #     )
    #     context.instance_eval do
    #       "I am #{name} and I am hiding #{@location}."
    #     end
    #     # => "I am Max Payne and I am hiding in a cheap motel."
    def initialize(hash)
      hash.each_pair do |key, value|
        # Build instance variable
        instance_variable_set('@' + key.to_s, value)

        # Define method
        metaclass = (class << self ; self ; end)
        metaclass.send(:define_method, key) { value }
      end
    end

    # Returns a binding for this instance.
    #
    # @return [Binding] A binding for this instance
    def get_binding
      binding
    end

  end
end
