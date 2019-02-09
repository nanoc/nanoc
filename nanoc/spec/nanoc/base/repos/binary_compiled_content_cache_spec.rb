# frozen_string_literal: true

describe Nanoc::Int::BinaryCompiledContentCache do
  let(:cache) { described_class.new(config: config) }

  let(:items) { [item] }

  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }
  let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:other_item) { Nanoc::Core::Item.new('asdf', {}, '/sneaky.md') }
  let(:other_item_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }

  let(:textual_content) { Nanoc::Core::Content.create('text') }
  let(:binary_content) do
    Nanoc::Core::Content.create(File.join(Dir.getwd, 'b1n4ry'), binary: true).tap do |c|
      File.open(c.filename, 'w') { |f| f.print(binary) }
    end
  end
  let(:binary) { 'b1n4ry' }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  it 'has no content by default' do
    expect(cache[item_rep]).to be_nil
  end

  describe 'setting content' do
    context 'item with textual content only' do
      before { cache[item_rep] = { last: textual_content } }

      it 'has no content' do
        expect(cache[item_rep]).to be_nil
      end
    end

    context 'item with binary content only' do
      let(:cache_file) do
        File.join(cache.filename,
                  item.identifier.to_s,
                  item_rep.name.to_s,
                  :last.to_s)
      end

      before do
        cache[item_rep] = {
          :last => binary_content,
          '.something'.to_sym => binary_content,
        }
      end

      it 'has content' do
        expect(File.read(cache[item_rep][:last].filename)).to eql(binary)
      end

      it 'yields files from cache' do
        expect(cache[item_rep][:last].filename).to eql(cache_file)
      end

      it 'has content for snapshots starting with a dot' do
        expect(cache[item_rep]).to include('.something'.to_sym)
      end
    end

    context 'item with mixed content' do
      before do
        cache[item_rep] = {
          binary: binary_content,
          textual: textual_content,
        }
      end

      it 'has binary content only' do
        expect(cache[item_rep].keys).to eq([:binary])
      end
    end

    context 'updating' do
      before do
        cache[item_rep] = { last: binary_content }
      end

      let(:retrieved) { cache[item_rep] }

      it 'succeeds' do
        cache[item_rep] = retrieved
      end
    end
  end

  describe 'after pruning' do
    context 'unknown item' do
      before do
        cache[other_item_rep] = { last: binary_content }

        cache.prune(items: items)
      end

      it 'has no content' do
        expect(cache[other_item_rep]).to be_nil
      end
    end

    context 'nested items' do
      let(:keep) { Nanoc::Core::Item.new('keep', {}, '/articles/keep/foo.md') }
      let(:keep_item_rep) { Nanoc::Core::ItemRep.new(keep, :default) }

      let(:remove) { Nanoc::Core::Item.new('remove', {}, '/articles/remove/foo.md') }
      let(:remove_item_rep) { Nanoc::Core::ItemRep.new(remove, :default) }

      let(:remove_dotted) { Nanoc::Core::Item.new('remove dotted', {}, '/articles/remove-dotted/foo.md') }
      let(:remove_dotted_item_rep) { Nanoc::Core::ItemRep.new(remove_dotted, :default) }

      before do
        cache[keep_item_rep] = { last: binary_content }
        cache[remove_item_rep] = { last: binary_content }
        cache[remove_dotted_item_rep] = { '.last'.to_sym => binary_content }

        cache.prune(items: [keep])
      end

      it 'has content for kept items' do
        expect(cache[keep_item_rep]).to be
      end

      it 'has no content for removed items' do
        expect(cache[remove_item_rep]).to be_nil
      end

      it 'has no content for removed items with snapshots starting with a dot' do
        expect(cache[remove_dotted_item_rep]).to be_nil
      end
    end
  end
end
