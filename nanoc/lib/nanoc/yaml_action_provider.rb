# frozen_string_literal: true

class YAMLActionProvider < Nanoc::Int::ActionProvider
  identifier :yaml

  def self.for(site)
    data = YAML.load(<<~EOF).__nanoc_symbolize_keys_recursively
      items:
        - match: "/**/*.md"
          actions:
            - filter: kramdown
            - write: "${item.identifier.without_ext}.html"
        - match: "/**/*.md"
          rep: raw
          actions:
            - write: "${item.identifier.without_ext}.txt"
        - match: "/**/*"
          actions:
            - write: "${item.identifier.without_ext}"

      layouts:
        - match: "/**/*"
          filter: erb
      EOF

    new(item_rules: data.fetch(:items), layout_rules: data.fetch(:layouts))
  end

  def initialize(item_rules:, layout_rules:)
    @item_rules = item_rules
    @layout_rules = layout_rules
  end

  def rep_names_for(item)
    @item_rules
      .select { |r| rule_matches_item?(r, item) }
      .map { |r| r.fetch(:rep, :default).to_sym }
      .uniq
  end

  def action_sequence_for(obj)
    case obj
    when Nanoc::Int::ItemRep
      rule = @item_rules.find { |r| rule_matches_rep?(r, obj) }
      # FIXME: what if rule is nil?

      Nanoc::Int::ActionSequence.build(obj) do |b|
        write_counter = 0

        # FIXME: add site
        config = Nanoc::Int::Configuration.new.with_defaults
        items = Nanoc::Int::ItemCollection.new(config)
        view_context = Nanoc::ViewContextForPreCompilation.new(items: items)
        context = Nanoc::Int::Context.new({
          item: Nanoc::BasicItemView.new(obj.item, view_context),
          rep: Nanoc::BasicItemRepView.new(obj, view_context),
          item_rep: Nanoc::BasicItemRepView.new(obj, view_context),
          # items: Nanoc::ItemCollectionWithoutRepsView.new(site.items, view_context),
          # layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
          # config: Nanoc::ConfigView.new(site.config, view_context),
        })

        rule.fetch(:actions).each do |raw_action|
          if raw_action.key?(:filter)
            # TODO: add params
            b.add_filter(raw_action.fetch(:filter).to_sym, {})
          elsif raw_action.key?(:layout)
            # TODO: add params
            b.add_layout(raw_action.fetch(:layout), {})
          elsif raw_action.key?(:write)
            snapshot_name = "_#{write_counter}".to_sym
            write_counter += 1
            path = raw_action.fetch(:write).gsub(/\$\{([^}]+)\}/) { |x| eval($1, context.get_binding) }
            b.add_snapshot(snapshot_name, path)
          else
            # TODO: support snapshot
            raise 'not suported yet'
          end
        end
      end
    when Nanoc::Int::Layout
      rule = @layout_rules.find { |r| rule_matches_layout?(r, obj) }
      # FIXME: what if rule is nil?

      Nanoc::Int::ActionSequence.build(obj) do |b|
        # TODO: add params
        b.add_filter(rule.fetch(:filter).to_sym, {})
      end
    else
      raise 'erm no'
    end

  end

  def need_preprocessing?
    false
  end

  def preprocess(_site)
  end

  def postprocess(_site, _reps)
  end

  private

  def rule_matches_layout?(rule, layout)
    Nanoc::Int::Pattern.from(rule.fetch(:match)).match?(layout.identifier)
  end

  def rule_matches_item?(rule, item)
    Nanoc::Int::Pattern.from(rule.fetch(:match)).match?(item.identifier)
  end

  def rule_matches_rep?(rule, rep)
    rule_matches_item?(rule, rep.item) && rule.fetch(:rep, :default).to_sym == rep.name
  end
end
