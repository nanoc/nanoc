module Nanoc::Extra

  # Nanoc::Extra::Context provides a context and a Binding for use in various
  # filters, such as the ERB and Haml one.
  class Context

    # Creates a new context based off the contents of the hash. Each pair in
    # the hash will be converted to an instance variable. For example, passing
    # the hash { :foo => 'bar' } will cause @foo to have the value "bar".
    def initialize(hash)
      hash.each_pair do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end

    # Returns a binding for this context.
    def get_binding
      binding
    end

  end
end
