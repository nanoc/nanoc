# frozen_string_literal: true

describe Nanoc::Core::TextualCompiledContentCache do
  let(:cache) { described_class.new(config:) }

  let(:items) { [item] }

  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }
  let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:other_item) { Nanoc::Core::Item.new('asdf', {}, '/sneaky.md') }
  let(:other_item_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }

  let(:content) { Nanoc::Core::Content.create('omg') }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  it 'has no content by default' do
    expect(cache[item_rep]).to be_nil
  end

  context 'setting content on known item' do
    before { cache[item_rep] = { last: content } }

    it 'has content' do
      expect(cache[item_rep][:last].string).to eql('omg')
    end

    context 'after storing and loading' do
      before do
        cache.store
        cache.load
      end

      it 'has content' do
        expect(cache[item_rep][:last].string).to eql('omg')
      end
    end
  end

  context 'setting content on unknown item' do
    before { cache[other_item_rep] = { last: content } }

    it 'has content' do
      expect(cache[other_item_rep][:last].string).to eql('omg')
    end

    context 'after storing and loading' do
      before do
        cache.store
        cache.load
      end

      it 'has content' do
        expect(cache[other_item_rep][:last].string).to eql('omg')
      end
    end

    context 'after pruning' do
      before do
        cache.prune(items:)
      end

      it 'has no content' do
        expect(cache[other_item_rep]).to be_nil
      end
    end
  end
end
