# frozen_string_literal: true

usage 'show-rules [thing]'
aliases :explain
summary 'describe the rules for each item'
description "
Prints the rules used for all items and layouts in the current site.
"

module Nanoc::CLI::Commands
  class ShowRules < ::Nanoc::CLI::CommandRunner
    def run
      load_site

      @c = Nanoc::CLI::ANSIStringColorizer

      compiler = site.compiler
      compiler.build_reps
      @reps = compiler.reps

      action_provider = site.compiler.action_provider
      unless action_provider.respond_to?(:rules_collection)
        raise(
          ::Nanoc::Int::Errors::GenericTrivial,
          'The show-rules command can only be used for sites with the Rule DSL action provider.',
        )
      end
      @rules = action_provider.rules_collection

      site.items.sort_by(&:identifier).each   { |e| explain_item(e) }
      site.layouts.sort_by(&:identifier).each { |e| explain_layout(e) }
    end

    def explain_item(item)
      puts "#{@c.c('Item ' + item.identifier, :bold, :yellow)}:"

      @reps[item].each do |rep|
        rule = @rules.compilation_rule_for(rep)
        puts "  Rep #{rep.name}: #{rule ? rule.pattern : '(none)'}"
      end

      puts
    end

    def explain_layout(layout)
      puts "#{@c.c('Layout ' + layout.identifier, :bold, :yellow)}:"

      found = false
      @rules.layout_filter_mapping.each do |pattern, _|
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
  end
end

runner Nanoc::CLI::Commands::ShowRules
