# frozen_string_literal: true

usage 'show-rules'
aliases :explain
summary 'describe the rules for each item'
description "
Prints the rules used for all items and layouts in the current site.
"
no_params

module Nanoc::OrigCLI::Commands
  class ShowRules < ::Nanoc::CLI::CommandRunner
    def run
      site = load_site

      res = Nanoc::Core::Compiler.new_for(site).run_until_reps_built
      reps = res.fetch(:reps)

      action_provider = Nanoc::Core::ActionProvider.named(site.config.action_provider).for(site)
      rules = action_provider.rules_collection

      items = site.items.sort_by(&:identifier)
      layouts = site.layouts.sort_by(&:identifier)

      items.each   { |e| explain_item(e, rules:, reps:) }
      layouts.each { |e| explain_layout(e, rules:) }
    end

    def explain_item(item, rules:, reps:)
      puts(fmt_heading("Item #{item.identifier}") + ':')

      reps[item].each do |rep|
        rule = rules.compilation_rule_for(rep)
        puts "  Rep #{rep.name}: #{rule ? rule.pattern : '(none)'}"
      end

      puts
    end

    def explain_layout(layout, rules:)
      puts(fmt_heading("Layout #{layout.identifier}") + ':')

      found = false
      rules.layout_filter_mapping.each_key do |pattern|
        if pattern.match?(layout.identifier)
          puts "  #{pattern}"
          found = true
          break
        end
      end
      unless found
        puts '  (none)'
      end

      puts
    end

    def fmt_heading(str)
      Nanoc::CLI::ANSIStringColorizer.c(str, :bold, :yellow)
    end
  end
end

runner Nanoc::OrigCLI::Commands::ShowRules
