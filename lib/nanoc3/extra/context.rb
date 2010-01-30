# encoding: utf-8

module Nanoc3::Extra

  # Nanoc3::Extra::Context provides a context and a Binding for use in various
  # filters, such as the ERB and Haml one.
  class Context

    # Creates a new context based off the contents of the hash. Each pair in
    # the hash will be converted to an instance variable and an instance
    # method. For example, passing the hash { :foo => 'bar' } will cause @foo
    # to have the value "bar", and the instance method #foo to return "bar".
    def initialize(hash)
      hash.each_pair do |key, value|
        # Build instance variable
        instance_variable_set('@' + key.to_s, value)

        # Define method
        metaclass = (class << self ; self ; end)
        metaclass.send(:define_method, key) { value }
      end
    end

    # Returns a binding for this context.
    def get_binding
      binding
    end

  end
end
