# frozen_string_literal: true

module Nanoc::RuleDSL
  class ActionProvider < Nanoc::Core::ActionProvider
    identifier :rule_dsl

    # @api private
    attr_reader :rules_collection

    def self.for(site)
      rules_collection = Nanoc::RuleDSL::RulesCollection.new

      action_sequence_calculator =
        Nanoc::RuleDSL::ActionSequenceCalculator.new(
          rules_collection:, site:,
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
      raise Nanoc::RuleDSL::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

      matching_rules.map(&:rep_name).uniq
    end

    def action_sequence_for(obj)
      @action_sequence_calculator[obj]
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
        Nanoc::Core::InMemoryDataSource.new(ctx.items._unwrap, ctx.layouts._unwrap, site.data_source)
    end

    def postprocess(site, compiler)
      dependency_tracker = Nanoc::Core::DependencyTracker::Null.new

      res = compiler.run_until_reps_built
      reps = res.fetch(:reps)

      view_context =
        Nanoc::Core::ViewContextForCompilation.new(
          reps:,
          items: site.items,
          dependency_tracker:,
          compilation_context: compiler.compilation_context(reps:),
          compiled_content_store: Nanoc::Core::CompiledContentStore.new,
        )
      ctx = new_postprocessor_context(site, view_context)

      @rules_collection.postprocessors.each_value do |postprocessor|
        ctx.instance_eval(&postprocessor)
      end
    end

    # @api private
    def new_preprocessor_context(site)
      view_context =
        Nanoc::Core::ViewContextForPreCompilation.new(items: site.items)

      Nanoc::Core::Context.new(
        config: Nanoc::Core::MutableConfigView.new(site.config, view_context),
        items: Nanoc::Core::MutableItemCollectionView.new(site.items, view_context),
        layouts: Nanoc::Core::MutableLayoutCollectionView.new(site.layouts, view_context),
      )
    end

    # @api private
    def new_postprocessor_context(site, view_context)
      Nanoc::Core::Context.new(
        config: Nanoc::Core::ConfigView.new(site.config, view_context),
        items: Nanoc::Core::PostCompileItemCollectionView.new(site.items, view_context),
      )
    end
  end
end
