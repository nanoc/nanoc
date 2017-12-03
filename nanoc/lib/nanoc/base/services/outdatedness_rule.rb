# frozen_string_literal: true

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
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement #apply')
    end

    contract C::None => String
    def inspect
      "#{self.class.name}(#{reason})"
    end

    def self.affects_props(*names)
      @affected_props = Set.new(names)
    end

    def self.affected_props
      @affected_props
    end
  end
end
