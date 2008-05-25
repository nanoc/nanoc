module Nanoc::CLI

  class InfoCommand < Command # :nodoc:

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
      # Check arguments
      if arguments.size != 0
        puts "usage: #{usage}"
        exit 1
      end

      # Get list of plugin classes
      plugins = {
        Nanoc::Filter     => 'Filters',
        Nanoc::DataSource => 'Data sources',
        Nanoc::Router     => 'Routers'
      }

      first = true

      plugins.to_a.sort_by { |i| i[1] }.each do |(klass, name)|
        # Find classes
        klasses = Nanoc::PluginManager.instance.find_all(klass)

        # Display
        puts unless first
        puts "#{name}:"
        puts
        klasses.sort_by { |k| k.identifier.to_s }.each do |klass|
          puts sprintf("    %-15s (%s)", klass.identifier.to_s, klass.to_s)
        end

        first = false
      end
    end

  end

end
