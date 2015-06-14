usage 'show-rules [thing]'
aliases :explain
summary 'describe the rules for each item'
description "
Prints the rules used for all items and layouts in the current site.
"

module Nanoc::CLI::Commands
  class ShowRules < ::Nanoc::CLI::CommandRunner
    def run
      require_site

      @c = Nanoc::CLI::ANSIStringColorizer
      @rules = site.compiler.rules_collection

      site.items.sort_by(&:identifier).each   { |e| explain_item(e) }
      site.layouts.sort_by(&:identifier).each { |e| explain_layout(e) }
    end

    def explain_item(item)
      puts "#{@c.c('Item ' + item.identifier, :bold, :yellow)}:"

      item.reps.each do |rep|
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
