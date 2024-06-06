# frozen_string_literal: true

describe Nanoc::Core::ChecksumStore do
  let(:store) { described_class.new(config:, objects:) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  let(:objects) { [item, code_snippet] }

  let(:item) { Nanoc::Core::Item.new('asdf', item_attributes, '/foo.md') }
  let(:other_item) { Nanoc::Core::Item.new('asdf', other_item_attributes, '/sneaky.md') }

  let(:item_attributes) { {} }
  let(:other_item_attributes) { {} }

  let(:code_snippet) { Nanoc::Core::CodeSnippet.new('def hi ; end', 'lib/foo.rb') }
  let(:other_code_snippet) { Nanoc::Core::CodeSnippet.new('def ho ; end', 'lib/bar.rb') }

  context 'nothing added' do
    it 'has no checksum' do
      expect(store[item]).to be_nil
    end

    it 'has no content checksum' do
      expect(store.content_checksum_for(item)).to be_nil
    end

    it 'has no attributes checksum' do
      expect(store.attributes_checksum_for(item)).to be_nil
    end
  end

  context 'setting content on known non-document' do
    before { store.add(code_snippet) }

    it 'has checksum' do
      expect(store[code_snippet]).not_to be_nil
    end

    it 'has no content checksum' do
      expect(store.content_checksum_for(code_snippet)).to be_nil
    end

    it 'has no attributes checksum' do
      expect(store.attributes_checksum_for(code_snippet)).to be_nil
    end

    context 'after storing and loading' do
      before do
        store.store
        store.load
      end

      it 'has checksum' do
        expect(store[code_snippet]).not_to be_nil
      end
    end
  end

  context 'after storing and loading missing data' do
    let(:code_snippet_a) { Nanoc::Core::CodeSnippet.new('aaa', 'lib/aaa.rb') }
    let(:code_snippet_b) { Nanoc::Core::CodeSnippet.new('bbb', 'lib/bbb.rb') }
    let(:code_snippet_c) { Nanoc::Core::CodeSnippet.new('ccc', 'lib/ccc.rb') }

    before do
      store.add(code_snippet_a)
      store.add(code_snippet_b)
      store.add(code_snippet_c)
      store.store

      # remove B
      store.objects = [code_snippet_a, code_snippet_c]
      store.load
    end

    it 'has checksums for A and C' do
      expect(store[code_snippet_a]).not_to be_nil
      expect(store[code_snippet_c]).not_to be_nil
    end
  end

  context 'setting content on unknown non-document' do
    before { store.add(other_code_snippet) }

    it 'has checksum' do
      expect(store[other_code_snippet]).not_to be_nil
    end

    it 'has no content checksum' do
      expect(store.content_checksum_for(other_code_snippet)).to be_nil
    end

    it 'has no attributes checksum' do
      expect(store.attributes_checksum_for(other_code_snippet)).to be_nil
    end

    context 'after storing and loading' do
      before do
        store.store
        store.load
      end

      it 'has no checksum' do
        expect(store[other_code_snippet]).to be_nil
      end
    end
  end

  context 'setting content on known item' do
    before { store.add(item) }

    it 'has checksum' do
      expect(store[item]).not_to be_nil
    end

    it 'has content checksum' do
      expect(store.content_checksum_for(item)).not_to be_nil
    end

    it 'has attributes checksum' do
      expect(store.attributes_checksum_for(item)).not_to be_nil
      expect(store.attributes_checksum_for(item)).to eq({})
    end

    context 'item has attributes' do
      let(:item_attributes) { { animal: 'donkey' } }

      it 'has attribute checksum for specified attribute' do
        expect(store.attributes_checksum_for(item)).to have_key(:animal)
      end
    end

    context 'after storing and loading' do
      before do
        store.store
        store.load
      end

      it 'has checksum' do
        expect(store[item]).not_to be_nil
      end
    end
  end

  context 'setting content on unknown item' do
    before { store.add(other_item) }

    it 'has checksum' do
      expect(store[other_item]).not_to be_nil
    end

    it 'has content checksum' do
      expect(store.content_checksum_for(other_item)).not_to be_nil
    end

    it 'has attributes checksum' do
      expect(store.attributes_checksum_for(other_item)).not_to be_nil
    end

    context 'item has attributes' do
      let(:other_item_attributes) { { location: 'Bernauer Str.' } }

      it 'has attribute checksum for specified attribute' do
        expect(store.attributes_checksum_for(other_item)).to have_key(:location)
      end
    end

    context 'after storing and loading' do
      before do
        store.store
        store.load
      end

      it 'has no checksum' do
        expect(store[other_item]).to be_nil
      end
    end
  end
end
