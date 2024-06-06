# frozen_string_literal: true

describe Nanoc::Core::BinaryCompiledContentCache do
  let(:cache) { described_class.new(config:) }

  let(:items) { [item] }

  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }
  let(:item_rep) { Nanoc::Core::ItemRep.new(item, :default) }

  let(:other_item) { Nanoc::Core::Item.new('asdf', {}, '/sneaky.md') }
  let(:other_item_rep) { Nanoc::Core::ItemRep.new(other_item, :default) }

  let(:content) do
    Nanoc::Core::Content.create(File.join(Dir.getwd, 'bin.dat'), binary: true).tap do |c|
      File.write(c.filename, 'b1n4ry')
    end
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  it 'has no content by default' do
    expect(cache[item_rep]).to be_nil
  end

  describe 'setting new content' do
    subject do
      cache[item_rep] = { last: content }
    end

    it 'sets content' do
      expect { subject }
        .to change { cache[item_rep] }
        .from(nil)
        .to(be_a(Hash))
    end

    it 'has correct content in cache' do
      subject
      expect(File.read(cache[item_rep][:last].filename)).to eql('b1n4ry')
    end

    it 'has correct filename in cache' do
      subject
      expect(cache[item_rep][:last].filename)
        .to match(%r{tmp/nanoc/[a-z0-9]+/binary_content_data/_foo_md-299726ada7/default-7505d64a54/last-213ed3ea45\z})
    end
  end

  describe 'setting empty content' do
    subject do
      cache[item_rep] = {}
    end

    it 'sets content' do
      expect { subject }
        .to change { cache[item_rep] }
        .from(nil)
        .to({})
    end
  end

  describe 'replacing existing content with itself' do
    subject do
      cache[item_rep] = cache[item_rep]
    end

    before do
      cache[item_rep] = { last: content }
    end

    it 'does not crash' do
      expect { subject }
        .not_to change { cache[item_rep][:last].filename }
    end
  end

  describe '#prune' do
    subject { cache.prune(items:) }

    before do
      cache[item_rep] = { last: content }
      cache[other_item_rep] = { last: content }
    end

    it 'empties content for unknown item' do
      expect { subject }
        .to change { cache[other_item_rep].nil? }
        .from(false)
        .to(true)
    end

    it 'retains content for known item' do
      expect { subject }
        .not_to change { cache[item_rep].nil? }
        .from(false)
    end

    it 'deletes content for unknown item' do
      pattern = 'tmp/nanoc/*/binary_content_data/*'
      is_sneaky_md = ->(fn) { fn.end_with?('/binary_content_data/_sneaky_md-e0111278e4') }

      expect { subject }
        .to change { Dir[pattern].any? { |e| is_sneaky_md.call(e) } }
        .from(true)
        .to(false)
    end

    it 'retains content for known item' do
      pattern = 'tmp/nanoc/*/binary_content_data/*'
      is_foo_md = ->(fn) { fn.end_with?('/binary_content_data/_foo_md-299726ada7') }

      expect { subject }
        .not_to change { Dir[pattern].any? { |e| is_foo_md.call(e) } }
        .from(true)
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
      cache[keep_item_rep] = { last: content }
      cache[remove_item_rep] = { last: content }
      cache[remove_dotted_item_rep] = { '.last': content }

      cache.prune(items: [keep])
    end

    it 'has content for kept items' do
      expect(cache[keep_item_rep]).not_to be_nil
    end

    it 'has no content for removed items' do
      expect(cache[remove_item_rep]).to be_nil
    end

    it 'has no content for removed items with snapshots starting with a dot' do
      expect(cache[remove_dotted_item_rep]).to be_nil
    end
  end
end
