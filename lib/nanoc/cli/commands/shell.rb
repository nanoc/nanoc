usage 'shell'
summary 'open a shell on the Nanoc environment'
aliases 'console'
description "
Open an IRB shell on a context that contains @items, @layouts, and @config.
"

module Nanoc::CLI::Commands
  class Shell < ::Nanoc::CLI::CommandRunner
    def run
      require 'pry'

      load_site

      ctx = Nanoc::Int::Context.new(env)
      if arguments.any? && Nanoc::Feature.enabled?(Nanoc::Feature::SHELL_EXEC)
        puts eval(arguments.join(' '), ctx.get_binding)
      else
        ctx.pry
      end
    end

    protected

    def env
      self.class.env_for_site(site)
    end

    def self.env_for_site(site)
      {
        items: Nanoc::ItemCollectionWithRepsView.new(site.items, nil),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, nil),
        config: Nanoc::ConfigView.new(site.config, nil),
      }
    end
  end
end

runner Nanoc::CLI::Commands::Shell
