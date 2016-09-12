module Nanoc::Extra
  # @api private
  module FishAutocompletion
    def generate
      root_cmd = Nanoc::CLI.root_command

      buf = ''

      # global options
      buf << "# global options\n"
      root_cmd.option_definitions.each do |opt_def|
        buf << 'complete -c nanoc'
        buf << ' -s ' << quote(opt_def[:short]) if opt_def[:short]
        buf << ' -l ' << quote(opt_def[:long]) if opt_def[:long]
        buf << ' -d ' << quote(opt_def[:desc])
        buf << ' -f'
        buf << "\n"
      end
      buf << "\n"

      # subcommands
      buf << "# subcommands\n"
      root_cmd.subcommands.each do |cmd|
        buf << "complete -c nanoc -n '__fish_use_subcommand' -xa "
        buf << quote(cmd.name)
        buf << ' -d ' << quote(cmd.summary)
        buf << ' -f'
        buf << "\n"
      end
      buf << "\n"

      # subcommand option details
      each_command(root_cmd) do |cmd, name|
        if cmd.option_definitions.any?
          buf << "# subcommand: #{name} -- option details\n"
          cmd.option_definitions.sort_by { |h| h[:short] || h[:long] }.each do |opt_def|
            buf << "complete -c nanoc -n 'contains #{quote name} (commandline -poc)'"
            buf << ' -s ' << quote(opt_def[:short]) if opt_def[:short]
            buf << ' -l ' << quote(opt_def[:long]) if opt_def[:long]
            buf << ' -d ' << quote(opt_def[:desc])
            values = values_for_option_definition(cmd, opt_def)
            if values
              buf << ' -x -a ' << quote(values)
            else
              buf << ' -f'
            end
            buf << "\n"
          end
          buf << "\n"
        end
      end

      # subcommand argument details
      each_command(root_cmd) do |cmd, name|
        values = values_for_command(cmd)
        if values
          buf << "# subcommand: #{name} -- argument details\n"
          case values
          when String
            buf << "complete -c nanoc -n 'contains #{name} (commandline -poc)'"
            buf << ' -x -a ' << quote(values)
            buf << "\n"
          when Array
            values.each do |(arg, desc)|
              buf << "complete -c nanoc -n 'contains #{name} (commandline -poc)'"
              buf << ' -x -a ' << quote(arg)
              buf << ' -d ' << quote(desc)
              buf << "\n"
            end
          end

          buf << "\n"
        end
      end

      buf
    end
    module_function :generate

    private

    def each_command(root_cmd)
      root_cmd.subcommands.each do |cmd|
        [cmd.name, *cmd.aliases].each do |name|
          yield(cmd, name)
        end
      end
    end
    module_function :each_command

    # Returns either a string, or a list of argument-description pairs
    def values_for_command(cmd)
      case cmd.name
      when 'check'
        '(nanoc autocomplete checks 2> /dev/null)'
      when 'help'
        Nanoc::CLI.root_command.subcommands.map { |c| [c.name, c.summary] }
      when 'deploy'
        '(nanoc autocomplete deploy_configs 2> /dev/null)'
      else
        nil
      end
    end
    module_function :values_for_command

    # Returns a string
    def values_for_option_definition(cmd, opt_def)
      case [cmd.name, opt_def[:long]]
      when %w(deploy target)
        '(nanoc autocomplete deploy_configs 2> /dev/null)'
      else
        nil
      end
    end
    module_function :values_for_option_definition

    def quote(s)
      '"' + escape(s) + '"'
    end
    module_function :quote

    def escape(s)
      s.gsub('\\', '\\\\').gsub('"', '\\"')
    end
    module_function :escape
  end
end
