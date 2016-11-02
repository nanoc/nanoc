usage 'autocomplete [options] [category]'
summary 'print possible values for the given category'
description "
Print all possible values for the given category. Supported categories are `checks` and `deploy_configs`, which will print all available check names and deployment targets, respectively.

This command is intended to facilitate the construction of autocompletions for shells.
"

module Nanoc::CLI::Commands
  class Autocomplete < ::Nanoc::CLI::CommandRunner
    def run
      if arguments.size != 1
        raise Nanoc::Int::Errors::GenericTrivial, "expected 1 argument, but #{arguments.size} were given"
      end

      case arguments[0]
      when 'checks'
        if site
          runner = Nanoc::Extra::Checking::Runner.new(site)
          runner.load_dsl_if_available
          checks = runner.all_check_classes
          puts checks.map(&:identifier).join("\n")
        end
      when 'deploy_configs'
        if site
          puts site.config.fetch(:deploy, {}).keys.join("\n")
        end
      else
        raise Nanoc::Int::Errors::GenericTrivial, "unknown entity_type: #{arguments[0]}"
      end
    end
  end
end

runner Nanoc::CLI::Commands::Autocomplete
