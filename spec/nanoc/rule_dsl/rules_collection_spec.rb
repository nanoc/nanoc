# frozen_string_literal: true

describe Nanoc::RuleDSL::RulesCollection do
  let(:rules_collection) { described_class.new }

  describe '#data' do
    subject { rules_collection.data }

    it 'is nil by default' do
      expect(subject).to be_nil
    end

    it 'can be set' do
      rules_collection.data = 'asdf'
      expect(subject).to eq('asdf')
    end
  end

  describe '#compilation_rule_for' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/foo.md') }

    let(:rep) { Nanoc::Int::ItemRep.new(item, rep_name) }

    let(:rep_name) { :default }

    subject { rules_collection.compilation_rule_for(rep) }

    context 'no rules' do
      it 'is nil' do
        expect(subject).to be_nil
      end
    end

    context 'some rules, none matching' do
      before do
        rules_collection.add_item_compilation_rule(rule)
      end

      let(:rule) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/bar.*'), :default, proc {})
      end

      it 'is nil' do
        expect(subject).to be_nil
      end
    end

    context 'some rules, one matching' do
      before do
        rules_collection.add_item_compilation_rule(rule_a)
        rules_collection.add_item_compilation_rule(rule_b)
      end

      let(:rule_a) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/foo.*'), :default, proc {})
      end

      let(:rule_b) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/bar.*'), :default, proc {})
      end

      context 'rep name does not match' do
        let(:rep_name) { :platypus }

        it 'is nil' do
          expect(subject).to be_nil
        end
      end

      context 'rep name matches' do
        it 'is the rule' do
          expect(subject).to equal(rule_a)
        end
      end
    end

    context 'some rules, multiple matching' do
      before do
        rules_collection.add_item_compilation_rule(rule_a)
        rules_collection.add_item_compilation_rule(rule_b)
        rules_collection.add_item_compilation_rule(rule_c)
      end

      let(:rule_a) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/foo.*'), :default, proc {})
      end

      let(:rule_b) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/*.*'), :default, proc {})
      end

      let(:rule_c) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/*.*'), :foo, proc {})
      end

      context 'no rep name matches' do
        let(:rep_name) { :platypus }

        it 'is the first matching rule' do
          expect(subject).to be_nil
        end
      end

      context 'one rep name matches' do
        let(:rep_name) { :foo }

        it 'is the first matching rule' do
          expect(subject).to equal(rule_c)
        end
      end

      context 'multiple rep names match' do
        it 'is the first matching rule' do
          expect(subject).to equal(rule_a)
        end
      end
    end
  end

  describe '#item_compilation_rules_for' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/foo.md') }

    subject { rules_collection.item_compilation_rules_for(item) }

    context 'no rules' do
      it 'is none' do
        expect(subject).to be_empty
      end
    end

    context 'some rules, none matching' do
      before do
        rules_collection.add_item_compilation_rule(rule)
      end

      let(:rule) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/bar.*'), :default, proc {})
      end

      it 'is none' do
        expect(subject).to be_empty
      end
    end

    context 'some rules, one matching' do
      before do
        rules_collection.add_item_compilation_rule(rule_a)
        rules_collection.add_item_compilation_rule(rule_b)
      end

      let(:rule_a) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/foo.*'), :default, proc {})
      end

      let(:rule_b) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/bar.*'), :default, proc {})
      end

      it 'is the single rule' do
        expect(subject).to contain_exactly(rule_a)
      end
    end

    context 'some rules, multiple matching' do
      before do
        rules_collection.add_item_compilation_rule(rule_a)
        rules_collection.add_item_compilation_rule(rule_b)
      end

      let(:rule_a) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/foo.*'), :default, proc {})
      end

      let(:rule_b) do
        Nanoc::RuleDSL::Rule.new(Nanoc::Int::Pattern.from('/*.*'), :default, proc {})
      end

      it 'is all matching rule' do
        expect(subject).to contain_exactly(rule_a, rule_b)
      end
    end
  end

  describe '#routing_rules_for' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/foo.md') }

    let(:rep) { Nanoc::Int::ItemRep.new(item, :default) }

    subject { rules_collection.routing_rules_for(rep) }

    let(:rules) do
      [
        # Matching item, matching rep
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/foo.*'), :default, proc {}, snapshot_name: :a
        ),
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/foo.*'), :default, proc {}, snapshot_name: :b
        ),

        # Matching item, non-matching rep
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/foo.*'), :raw, proc {}, snapshot_name: :a
        ),
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/foo.*'), :raw, proc {}, snapshot_name: :b
        ),

        # Non-matching item, matching rep
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/bar.*'), :default, proc {}, snapshot_name: :a
        ),
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/bar.*'), :default, proc {}, snapshot_name: :b
        ),

        # Non-matching item, non-matching rep
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/bar.*'), :raw, proc {}, snapshot_name: :a
        ),
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/bar.*'), :raw, proc {}, snapshot_name: :b
        ),

        # Matching item, matching rep, but not the first
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/*.*'), :default, proc {}, snapshot_name: :a
        ),
        Nanoc::RuleDSL::Rule.new(
          Nanoc::Int::Pattern.from('/*.*'), :default, proc {}, snapshot_name: :b
        ),
      ]
    end

    before do
      rules.each do |rule|
        rules_collection.add_item_routing_rule(rule)
      end
    end

    it 'returns the first matching rule for every snapshot' do
      expect(subject).to eq(
        a: rules[0],
        b: rules[1],
      )
    end
  end

  describe '#filter_for_layout' do
    let(:layout) { Nanoc::Int::Layout.new('Some content', {}, '/foo.md') }

    subject { rules_collection.filter_for_layout(layout) }

    let(:mapping) { {} }

    before do
      mapping.each_pair do |key, value|
        rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(key)] = value
      end
    end

    context 'no rules' do
      it { is_expected.to be_nil }
    end

    context 'one non-matching rule' do
      let(:mapping) do
        {
          '/default.*' => [:erb, {}],
        }
      end

      it { is_expected.to be_nil }
    end

    context 'one matching rule' do
      let(:mapping) do
        {
          '/foo.*' => [:erb, {}],
        }
      end

      it 'is the single one' do
        expect(subject).to eq([:erb, {}])
      end
    end

    context 'multiple matching rules' do
      let(:mapping) do
        {
          '/foo.*' => [:erb, {}],
          '/*' => [:haml, {}],
        }
      end

      it 'is the first one' do
        expect(subject).to eq([:erb, {}])
      end
    end
  end
end
