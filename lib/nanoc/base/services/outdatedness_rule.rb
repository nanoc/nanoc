module Nanoc::Int
  # @api private
  class OutdatednessRule
    include Nanoc::Int::ContractsSupport
    include Singleton

    def call(obj, outdatedness_checker)
      Nanoc::Int::NotificationCenter.post(:outdatedness_rule_started, self.class, obj)
      apply(obj, outdatedness_checker)
    ensure
      Nanoc::Int::NotificationCenter.post(:outdatedness_rule_ended, self.class, obj)
    end

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
