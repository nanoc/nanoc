# frozen_string_literal: true

describe Nanoc::Core::CompiledContentCache do
  let(:cache) { described_class.new(config:) }

  let(:items) { [item] }

  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }
  let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:other_item) { Nanoc::Core::Item.new('asdf', {}, '/sneaky.md') }
  let(:other_item_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }

  let(:textual_content) do
    Nanoc::Core::Content.create('text')
  end

  let(:binary_content) do
    Nanoc::Core::Content.create(File.join(Dir.getwd, 'bin.dat'), binary: true).tap do |c|
      File.write(c.filename, 'b1n4ry')
    end
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  it 'has no content by default' do
    expect(cache[item_rep]).to be_nil
  end

  shared_examples 'properly-functioning compiled content cache' do
    context 'setting only textual content' do
      before do
        cache[target_item_rep] = {
          aaa: textual_content,
        }
      end

      it 'has content' do
        expect(cache[target_item_rep][:aaa].string).to eql(textual_content.string)
      end

      context 'after storing and loading' do
        before do
          cache.store
          cache.load
        end

        it 'has content' do
          expect(cache[target_item_rep][:aaa].string).to eql(textual_content.string)
        end
      end

      context 'after pruning all items' do
        before do
          cache.prune(items: [])
        end

        it 'has no content' do
          expect(cache[target_item_rep]).to be_nil
        end
      end

      context 'after pruning no items' do
        before do
          cache.prune(items: [target_item_rep.item])
        end

        it 'has no content' do
          expect(cache[target_item_rep]).not_to be_nil
        end
      end
    end

    context 'setting textual and binary content' do
      before do
        cache[target_item_rep] = {
          aaa: textual_content,
          bbb: binary_content,
        }
      end

      it 'has content' do
        expect(cache[target_item_rep][:aaa].string).to eql(textual_content.string)

        expect(File.read(cache[target_item_rep][:bbb].filename))
          .to eql('b1n4ry')
      end

      context 'after storing and loading' do
        before do
          cache.store
          cache.load
        end

        it 'has content' do
          expect(cache[target_item_rep][:aaa].string).to eql(textual_content.string)

          expect(File.read(cache[target_item_rep][:bbb].filename))
            .to eql('b1n4ry')
        end
      end

      context 'after pruning all items' do
        before do
          cache.prune(items: [])
        end

        it 'has no content' do
          expect(cache[target_item_rep]).to be_nil
        end
      end

      context 'after pruning no items' do
        before do
          cache.prune(items: [target_item_rep.item])
        end

        it 'has no content' do
          expect(cache[target_item_rep]).not_to be_nil
        end
      end
    end

    context 'setting only binary content' do
      before do
        cache[target_item_rep] = {
          bbb: binary_content,
        }
      end

      it 'has content' do
        expect(File.read(cache[target_item_rep][:bbb].filename))
          .to eql('b1n4ry')
      end

      context 'after storing and loading' do
        before do
          cache.store
          cache.load
        end

        it 'has content' do
          expect(File.read(cache[target_item_rep][:bbb].filename))
            .to eql('b1n4ry')
        end
      end

      context 'after pruning all items' do
        before do
          cache.prune(items: [])
        end

        it 'has no content' do
          expect(cache[target_item_rep]).to be_nil
        end
      end

      context 'after pruning no items' do
        before do
          cache.prune(items: [target_item_rep.item])
        end

        it 'has no content' do
          expect(cache[target_item_rep]).not_to be_nil
        end
      end
    end
  end

  context 'setting content on known item' do
    let(:target_item_rep) { item_rep }

    include_examples 'properly-functioning compiled content cache'
  end

  context 'setting content on unknown item' do
    let(:target_item_rep) { other_item_rep }

    include_examples 'properly-functioning compiled content cache'
  end
end
