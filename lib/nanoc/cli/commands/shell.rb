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

      require_site

      Nanoc::Int::Context.new(env).pry
    end

    protected

    def env
      self.class.env_for_site(site)
    end

    def self.env_for(site)
      {
        items: Nanoc::ItemCollectionView.new(site.items),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts),
        config: Nanoc::ConfigView.new(site.config),
      }
    end
  end
end

runner Nanoc::CLI::Commands::Shell
