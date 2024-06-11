# frozen_string_literal: true

usage 'compile [options]'
summary 'compile items of this site'
description <<~EOS
  Compile all items of the current site.
EOS
no_params

flag nil, :diff, 'generate diff'
flag :W, :watch, 'watch for changes and recompile when needed'
option nil, :focus, 'compile only items matching the given pattern', argument: :required, multiple: true

module Nanoc::CLI::Commands
  class Compile < ::Nanoc::CLI::CommandRunner
    attr_accessor :listener_classes

    def run
      self.class.enter_site_dir

      if options[:watch]
        run_repeat
      else
        run_once
      end
    end

    def run_repeat
      require 'nanoc/live'
      Nanoc::Live::LiveRecompiler.new(command_runner: self, focus: options[:focus]).run
    end

    def run_once
      time_before = Time.now

      @site = load_site

      puts 'Compiling site…'
      compiler = Nanoc::Core::Compiler.new_for(@site, focus: options[:focus])
      listener = Nanoc::CLI::CompileListeners::Aggregate.new(
        command_runner: self,
        site: @site,
        compiler:,
      )
      listener.run_while do
        compiler.run_until_end
      end

      time_after = Time.now
      puts
      puts "Site compiled in #{format('%.2f', time_after - time_before)}s."

      if options[:focus]
        warn 'CAUTION: A --focus option is specified. Not the entire site has been compiled.'
        warn 'Re-run without --focus to compile the entire site.'
      end
    end
  end
end

runner Nanoc::CLI::Commands::Compile
