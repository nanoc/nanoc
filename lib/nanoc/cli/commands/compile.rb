# frozen_string_literal: true

usage 'compile [options]'
summary 'compile items of this site'
description <<~EOS
  Compile all items of the current site.
EOS
flag nil, :diff, 'generate diff'

module Nanoc::CLI::Commands
  class Compile < ::Nanoc::CLI::CommandRunner
    attr_accessor :listener_classes

    def run
      time_before = Time.now

      @site = load_site

      puts 'Compiling site…'
      compiler = Nanoc::Int::Compiler.new_for(@site)
      listener = Nanoc::CLI::Commands::CompileListeners::Aggregate.new(
        command_runner: self,
        site: @site,
        compiler: compiler,
      )
      listener.run_while do
        compiler.run_until_end
      end

      time_after = Time.now
      puts
      puts "Site compiled in #{format('%.2f', time_after - time_before)}s."
    end
  end
end

runner Nanoc::CLI::Commands::Compile
