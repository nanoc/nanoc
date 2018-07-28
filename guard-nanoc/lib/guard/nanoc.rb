# encoding: utf-8

require 'guard/compat/plugin'

require 'nanoc'
require 'nanoc/cli'

module Guard
  class Nanoc < Plugin
    def self.live_cmd
      @_live_cmd ||= begin
        path = File.join(File.dirname(__FILE__), '..', 'nanoc', 'cli', 'commands', 'live.rb')
        ::Nanoc::CLI.load_command_at(path)
      end
    end

    def initialize(options={})
      @dir = options[:dir] || '.'
      super
    end

    def start
      self.setup_listeners
      self.recompile_in_subprocess
    end

    def run_all
      self.recompile_in_subprocess
    end

    def run_on_changes(paths)
      self.recompile_in_subprocess
    end

    def run_on_removals(paths)
      self.recompile_in_subprocess
    end

  protected

    def setup_listeners
      ::Nanoc::CLI.setup

      ::Nanoc::CLI::Commands::CompileListeners::FileActionPrinter
        .new(reps: [])
        .start
    end

    def recompile_in_subprocess
      if Process.respond_to?(:fork)
        pid = Process.fork { self.recompile }
        Process.waitpid(pid)
      else
        self.recompile
      end
    end

    def recompile
      Dir.chdir(@dir) do
        site = ::Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile
      end
      self.notify_success
    rescue => e
      self.notify_failure
      ::Nanoc::CLI::ErrorHandler.print_error(e)
    end

    def notify_success
      Compat::UI.notify('Compilation succeeded', :title => 'nanoc', :image => :success)
      Compat::UI.info 'Compilation succeeded.'
    end

    def notify_failure
      Compat::UI.notify('Compilation FAILED', :title => 'nanoc', :image => :failed)
      Compat::UI.error 'Compilation failed!'
    end
  end
end

::Nanoc::CLI.after_setup do
  ::Nanoc::CLI.add_command(Guard::Nanoc.live_cmd)
end
