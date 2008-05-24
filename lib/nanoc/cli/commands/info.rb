module Nanoc::CLI

  class InfoCommand < Command

    def name
      'info'
    end

    def aliases
      []
    end

    def short_desc
      'show info about available plugins'
    end

    def long_desc
      'Show a list of available plugins, including filters, data sources ' +
      'and routers.'
    end

    def usage
      "nanoc info"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      # Get list of plugin classes
      plugins = {
        Nanoc::Filter     => 'Filters',
        Nanoc::DataSource => 'Data sources',
        Nanoc::Router     => 'Routers'
      }

      first = true

      plugins.each_pair do |klass, name|
        # Find classes
        klasses = Nanoc::PluginManager.instance.find_all(klass)

        # Display
        puts unless first
        puts "#{name}:"
        puts
        klasses.sort_by { |k| k.identifier.to_s }.each do |klass|
          puts "    " + klass.identifier.to_s
        end

        first = false
      end
    end

  end

end
