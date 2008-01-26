module Nanoc
  class Plugin

    class << self
      attr_accessor :_identifiers
    end

    def self.identifiers(*identifiers)
      self._identifiers = [] unless instance_variables.include?('@_identifiers')
      identifiers.empty? ? self._identifiers || [] : self._identifiers = (self._identifiers || []) + identifiers
    end

    def self.identifier(identifier=nil)
      self._identifiers = [] unless instance_variables.include?('@_identifiers')
      identifier.nil? ? self.identifiers.first : self.identifiers(identifier)
    end

  end
end
