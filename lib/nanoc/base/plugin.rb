module Nanoc
  class Plugin

    # Attributes

    class << self
      attr_accessor :_requirements
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
