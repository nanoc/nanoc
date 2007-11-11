Nanoc.load_file('base', 'plugin.rb')

module Nanoc
  class Filter < Plugin

    # Attributes

    class << self
      attr_accessor :_names
    end

    def self.name(name=nil)
      self.names(name)
    end

    def self.names(*names)
      if names.empty?
        self._names
      else
        self._names ||= []
        names.each do |name|
          self._names << name
          $nanoc_extras_manager.register_filter(name, self)
        end
      end
    end

    # Misc

    def initialize(page, pages, config)
      @page   = page
      @pages  = pages
      @config = config
    end

    def run(content)
      $stderr.puts 'ERROR: Filter#run must be overridden'
      exit(1)
    end

  end
end
