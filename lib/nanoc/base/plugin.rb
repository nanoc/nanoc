module Nanoc
  class Plugin

    # Attributes

    class << self
      attr_accessor :_name
      attr_accessor :_requirements
    end

    def self.name(name=nil)
      name.nil? ? self._name : self._name = name
    end

    def self.requires(*names)
      self._requirements ||= []
      names.each { |name| self._requirements << name }
    end

    def self.requirements
      self._requirements || []
    end

  end
end
