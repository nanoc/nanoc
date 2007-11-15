module Nanoc
  class Plugin

    class << self
      attr_accessor :_identifiers
      attr_accessor :_version
    end

    # Identifiers

    def self.identifiers(*identifiers)
      identifiers.empty? ? self._identifiers || [] : self._identifiers = (self._identifiers || []) + identifiers
    end

    def self.identifier(identifier=nil)
      identifier.nil? ? self.identifiers.first : self.identifiers(identifier)
    end

    # Version

    def self.version(version=nil)
      version.nil? ? self._version : self._version = version
    end

  end
end
