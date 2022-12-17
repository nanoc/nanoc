# frozen_string_literal: true

require 'guard/compat/plugin'

require 'nanoc'
require 'nanoc/orig_cli'

module Guard
  class Nanoc < Plugin
    def self.live_cmd
      @_live_cmd ||= begin
        path = File.join(File.dirname(__FILE__), 'nanoc', 'live_command.rb')
        Cri::Command.load_file(path, infer_name: true)
      end
    end

    def initialize(options = {})
      @dir = options[:dir] || '.'
      super
    end

    def start
      setup_listeners
      recompile_in_subprocess
    end

    def run_all
      recompile_in_subprocess
    end

    def run_on_changes(_paths)
      recompile_in_subprocess
    end

    def run_on_removals(_paths)
      recompile_in_subprocess
    end

    protected

    def setup_listeners
      ::Nanoc::CLI.setup

      ::Nanoc::CLI::CompileListeners::FileActionPrinter
        .new(reps: [])
        .start_safely
    end

    def recompile_in_subprocess
      if Process.respond_to?(:fork)
        pid = Process.fork { recompile }
        Process.waitpid(pid)
      else
        recompile
      end
    end

    def recompile
      # Necessary, because forking and threading don’t work together.
      ::Nanoc::Core::NotificationCenter.force_reset

      Dir.chdir(@dir) do
        site = ::Nanoc::Core::SiteLoader.new.new_from_cwd
        ::Nanoc::Core::Compiler.compile(site)
      end
      notify_success
    rescue => e
      notify_failure
      ::Nanoc::CLI::ErrorHandler.print_error(e)
    end

    def notify_success
      Compat::UI.notify('Compilation succeeded', title: 'nanoc', image: :success)
      Compat::UI.info 'Compilation succeeded.'
    end

    def notify_failure
      Compat::UI.notify('Compilation FAILED', title: 'nanoc', image: :failed)
      Compat::UI.error 'Compilation failed!'
    end
  end
end

Nanoc::CLI.after_setup do
  Nanoc::CLI.add_command(Guard::Nanoc.live_cmd)
end
