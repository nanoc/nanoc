usage 'shell'
summary 'open a shell on the nanoc environment'
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
        items: Nanoc::ItemCollectionView.new(site.items, nil),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, nil),
        config: Nanoc::ConfigView.new(site.config, nil),
      }
    end
  end
end

runner Nanoc::CLI::Commands::Shell
