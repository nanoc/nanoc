describe Nanoc::Int::ChecksumStore do
  let(:store) { described_class.new }

  let(:items) { [item] }

  let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }
  let(:other_item) { Nanoc::Int::Item.new('asdf', {}, '/sneaky.md') }

  let(:code_snippet) { Nanoc::Int::CodeSnippet.new('def hi ; end', 'lib/foo.rb') }
  let(:other_code_snippet) { Nanoc::Int::CodeSnippet.new('def ho ; end', 'lib/bar.rb') }

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
        # FIXME: should be nil
        expect(store[other_code_snippet]).not_to be_nil
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

    context 'after storing and loading' do
      before do
        store.store
        store.load
      end

      it 'has no checksum' do
        # FIXME: should be nil
        expect(store[other_item]).not_to be_nil
      end
    end
  end
end
