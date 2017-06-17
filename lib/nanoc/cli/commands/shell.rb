# frozen_string_literal: true

usage 'shell'
summary 'open a shell on the Nanoc environment'
aliases 'console'
description "
Open an IRB shell on a context that contains @items, @layouts, and @config.
"
flag :p, :preprocess, 'run preprocessor'

module Nanoc::CLI::Commands
  class Shell < ::Nanoc::CLI::CommandRunner
    def run
      require 'pry'

      load_site(preprocess: options[:preprocess])

      Nanoc::Int::Context.new(env).pry
    end

    def env
      self.class.env_for_site(site)
    end

    def self.reps_for(site)
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        action_provider = Nanoc::Int::ActionProvider.named(:rule_dsl).for(site)
        builder = Nanoc::Int::ItemRepBuilder.new(site, action_provider, reps)
        builder.run
      end
    end

    def self.view_context_for(site)
      Nanoc::ViewContext.new(
        reps: reps_for(site),
        items: site.items,
        dependency_tracker: Nanoc::Int::DependencyTracker::Null.new,
        compilation_context: nil,
        snapshot_repo: nil,
      )
    end

    def self.env_for_site(site)
      view_context = view_context_for(site)

      {
        items: Nanoc::ItemCollectionWithRepsView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
      }
    end
  end
end

runner Nanoc::CLI::Commands::Shell
