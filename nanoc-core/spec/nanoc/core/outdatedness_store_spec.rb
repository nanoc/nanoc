# frozen_string_literal: true

describe Nanoc::Core::OutdatednessStore do
  subject(:store) { described_class.new(config:) }

  let(:item) { Nanoc::Core::Item.new('foo', {}, '/foo.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :foo) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:items) { [] }
  let(:layouts) { [] }
  let(:code_snippets) { [] }

  describe '#include?, #add and #remove' do
    subject { store.include?(rep) }

    context 'nothing added' do
      it { is_expected.to be(false) }
    end

    context 'rep added' do
      before { store.add(rep) }

      it { is_expected.to be(true) }
    end

    context 'rep added and removed' do
      before do
        store.add(rep)
        store.remove(rep)
      end

      it { is_expected.to be(false) }
    end

    context 'rep added, removed, and added again' do
      before do
        store.add(rep)
        store.remove(rep)
        store.add(rep)
      end

      it { is_expected.to be(true) }
    end
  end

  describe 'reloading' do
    subject do
      store.store
      store.load
      store.include?(rep)
    end

    context 'not added' do
      it { is_expected.to be(false) }
    end

    context 'added' do
      before { store.add(rep) }

      it { is_expected.to be(true) }
    end
  end
end
