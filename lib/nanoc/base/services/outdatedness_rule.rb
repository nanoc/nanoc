module Nanoc::Int
  # @api private
  class OutdatednessRule
    include Nanoc::Int::ContractsSupport
    include Singleton

    def apply(_obj, _outdatedness_checker)
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement ##reason, and #apply')
    end

    contract C::None => String
    def inspect
      "#{self.class.name}(#{reason})"
    end

    # TODO: remove
    def reason
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement ##reason, and #apply')
    end
  end
end
