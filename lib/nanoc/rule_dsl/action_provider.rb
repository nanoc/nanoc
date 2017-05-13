# frozen_string_literal: true

module Nanoc::RuleDSL
  class ActionProvider < Nanoc::Int::ActionProvider
    identifier :rule_dsl

    # @api private
    attr_reader :rules_collection

    def self.for(site)
      rules_collection = Nanoc::RuleDSL::RulesCollection.new

      action_sequence_calculator =
        Nanoc::RuleDSL::ActionSequenceCalculator.new(
          rules_collection: rules_collection, site: site,
        )

      action_provider = new(rules_collection, action_sequence_calculator)

      Nanoc::RuleDSL::RulesLoader.new(site.config, rules_collection).load

      action_provider
    end

    def initialize(rules_collection, action_sequence_calculator)
      @rules_collection = rules_collection
      @action_sequence_calculator = action_sequence_calculator
    end

    def rep_names_for(item)
      matching_rules = @rules_collection.item_compilation_rules_for(item)
      raise Nanoc::Int::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

      matching_rules.map(&:rep_name).uniq
    end

    def action_sequence_for(rep)
      @action_sequence_calculator[rep]
    end

    def need_preprocessing?
      @rules_collection.preprocessors.any?
    end

    def preprocess(site)
      ctx = new_preprocessor_context(site)

      @rules_collection.preprocessors.each_value do |preprocessor|
        ctx.instance_eval(&preprocessor)
      end

      site.data_source =
        Nanoc::Int::InMemDataSource.new(ctx.items.unwrap, ctx.layouts.unwrap)
    end

    def postprocess(site, reps)
      dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
      view_context =
        Nanoc::ViewContext.new(
          reps: reps,
          items: site.items,
          dependency_tracker: dependency_tracker,
          compilation_context: site.compiler.compilation_context,
          snapshot_repo: nil,
        )
      ctx = new_postprocessor_context(site, view_context)

      @rules_collection.postprocessors.each_value do |postprocessor|
        ctx.instance_eval(&postprocessor)
      end
    end

    # @api private
    def new_preprocessor_context(site)
      dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
      view_context =
        Nanoc::ViewContext.new(
          reps: nil,
          items: nil,
          dependency_tracker: dependency_tracker,
          compilation_context: nil,
          snapshot_repo: nil,
        )

      Nanoc::Int::Context.new(
        config: Nanoc::MutableConfigView.new(site.config, view_context),
        items: Nanoc::MutableItemCollectionView.new(site.items, view_context),
        layouts: Nanoc::MutableLayoutCollectionView.new(site.layouts, view_context),
      )
    end

    # @api private
    def new_postprocessor_context(site, view_context)
      Nanoc::Int::Context.new(
        config: Nanoc::ConfigView.new(site.config, view_context),
        items: Nanoc::PostCompileItemCollectionView.new(site.items, view_context),
      )
    end
  end
end
