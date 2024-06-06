# frozen_string_literal: true

describe Nanoc::Core::ActionSequenceStore do
  let(:store) { described_class.new(config:) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe '#[]' do
    subject { store[obj] }

    let(:known_obj) { Nanoc::Core::Item.new('asdf', {}, '/asdf.md') }
    let(:unknown_obj) { Nanoc::Core::Item.new('fdsa', {}, '/fdsa.md') }

    let(:some_action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:foo, {})
      end
    end

    before do
      store[known_obj] = some_action_sequence
    end

    context 'obj is not known' do
      let(:obj) { unknown_obj }

      it { is_expected.to be_nil }
    end

    context 'obj is known' do
      let(:obj) { known_obj }

      it { is_expected.to eq(some_action_sequence) }
    end
  end

  describe 'load and store' do
    subject do
      store.store
      store.load
    end

    let(:known_obj) { Nanoc::Core::Item.new('asdf', {}, '/asdf.md') }
    let(:unknown_obj) { Nanoc::Core::Item.new('fdsa', {}, '/fdsa.md') }

    let(:some_action_sequence) do
      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(:foo, {})
      end
    end

    before do
      store[known_obj] = some_action_sequence
    end

    it 'retains its data' do
      expect(store[known_obj]).to eq(some_action_sequence)
      expect(store[unknown_obj]).to be_nil
    end
  end
end
