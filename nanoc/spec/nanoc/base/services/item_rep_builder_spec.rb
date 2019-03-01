# frozen_string_literal: true

describe Nanoc::Int::ItemRepBuilder do
  describe '.snapshot_defs' do
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :default) }

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_b2b
      type :binary => :binary # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_b2t
      type :binary => :text # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_t2t
      type :text => :text # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    Class.new(Nanoc::Filter) do
      identifier :RuleMemSpec_filter_t2b
      type :text => :binary # rubocop:disable Style/HashSyntax

      def run(content, params = {}); end
    end

    it 'has no snapshot defs by default' do
      action_sequence =
        Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
        end

      snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
      expect(snapshot_defs).to be_empty
    end

    context 'textual item' do
      let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

      it 'generates initial textual snapshot def' do
        action_sequence =
          Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
          end

        snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
        expect(snapshot_defs.size).to eq(1)
        expect(snapshot_defs[0].name).to eq(:giraffe)
        expect(snapshot_defs[0]).not_to be_binary
      end

      it 'generated follow-up textual snapshot def if previous filter is textual' do
        action_sequence =
          Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_t2t, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
        expect(snapshot_defs.size).to eq(2)
        expect(snapshot_defs[0].name).to eq(:giraffe)
        expect(snapshot_defs[0]).not_to be_binary
        expect(snapshot_defs[1].name).to eq(:zebra)
        expect(snapshot_defs[1]).not_to be_binary
      end

      it 'generated follow-up binary snapshot def if previous filter is text-to-bianry' do
        action_sequence =
          Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_t2b, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
        expect(snapshot_defs.size).to eq(2)
        expect(snapshot_defs[0].name).to eq(:giraffe)
        expect(snapshot_defs[0]).not_to be_binary
        expect(snapshot_defs[1].name).to eq(:zebra)
        expect(snapshot_defs[1]).to be_binary
      end
    end

    context 'binary item' do
      let(:item) { Nanoc::Core::Item.new(Nanoc::Core::BinaryContent.new('/asdf.dat'), {}, '/foo.md') }

      it 'generates initial binary snapshot def' do
        action_sequence =
          Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
          end

        snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
        expect(snapshot_defs.size).to eq(1)
        expect(snapshot_defs[0].name).to eq(:giraffe)
        expect(snapshot_defs[0]).to be_binary
      end

      it 'generated follow-up binary snapshot def if previous filter is binary' do
        action_sequence =
          Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_b2b, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
        expect(snapshot_defs.size).to eq(2)
        expect(snapshot_defs[0].name).to eq(:giraffe)
        expect(snapshot_defs[0]).to be_binary
        expect(snapshot_defs[1].name).to eq(:zebra)
        expect(snapshot_defs[1]).to be_binary
      end

      it 'generated follow-up textual snapshot def if previous filter is binary-to-text' do
        action_sequence =
          Nanoc::Int::ActionSequenceBuilder.build(rep) do |b|
            b.add_snapshot(:giraffe, nil)
            b.add_filter(:RuleMemSpec_filter_b2t, arguments: 'irrelevant')
            b.add_snapshot(:zebra, nil)
          end

        snapshot_defs = described_class.send(:snapshot_defs_for, action_sequence)
        expect(snapshot_defs.size).to eq(2)
        expect(snapshot_defs[0].name).to eq(:giraffe)
        expect(snapshot_defs[0]).to be_binary
        expect(snapshot_defs[1].name).to eq(:zebra)
        expect(snapshot_defs[1]).not_to be_binary
      end
    end
  end
end
