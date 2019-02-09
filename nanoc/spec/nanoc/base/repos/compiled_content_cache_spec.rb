# frozen_string_literal: true

describe Nanoc::Int::CompiledContentCache do\
  let(:cache) { described_class.new(config: config) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe 'storage and retrieval' do
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo.md') }

    let(:item_rep) do
      Nanoc::Core::ItemRep.new(item, :default).tap do |r|
        r.snapshot_defs = [
          Nanoc::Core::SnapshotDef.new(:textual, binary: false),
          Nanoc::Core::SnapshotDef.new(:binary, binary: true),
        ]
      end
    end

    let(:textual_content) { Nanoc::Core::Content.create('text') }
    let(:binary_content) do
      Nanoc::Core::Content.create(File.join(Dir.getwd, 'b1n4ry'), binary: true).tap do |c|
        File.open(c.filename, 'w') { |f| f.print(binary) }
      end
    end
    let(:binary) { 'b1n4ry' }

    context "cache item matches item rep's snapshot_defs" do
      before do
        cache[item_rep] = {
          textual: textual_content,
          binary: binary_content,
        }
      end

      it 'retrieves stored item' do
        expect(cache[item_rep]).to be
      end
    end

    context 'cache item has extra keys' do
      before do
        cache[item_rep] = {
          textual: textual_content,
          binary: binary_content,
          extra: textual_content,
        }
      end

      it 'has no cache item' do
        expect(cache[item_rep]).to be_nil
      end
    end

    context "item rep's snapshot_defs has extra keys" do
      before do
        item_rep.snapshot_defs += [Nanoc::Core::SnapshotDef.new(:extra, binary: false)]

        cache[item_rep] = {
          textual: textual_content,
          binary: binary_content,
        }
      end

      it 'has no cache item' do
        expect(cache[item_rep]).to be_nil
      end
    end

    context "item rep's snapshot_defs types does not match cache" do
      before do
        cache[item_rep] = {
          textual: textual_content,
          binary: textual_content,
        }
      end

      it 'has no cache item' do
        expect(cache[item_rep]).to be_nil
      end
    end
  end

  describe 'delegation' do
    shared_context 'delegates to wrapped caches' do
      let(:textual) { instance_double(Nanoc::Int::TextualCompiledContentCache).as_null_object }
      let(:binary) { instance_double(Nanoc::Int::BinaryCompiledContentCache).as_null_object }

      let(:expect_args) { args.nil? ? no_args : args }

      before do
        allow(Nanoc::Int::TextualCompiledContentCache).to receive(:new).and_return(textual)
        allow(Nanoc::Int::BinaryCompiledContentCache).to receive(:new).and_return(binary)

        if args.nil?
          cache.public_send(meth)
        else
          cache.public_send(meth, args)
        end
      end

      it 'delegates to textual compiled content cache' do
        expect(textual).to have_received(meth).with(expect_args)
      end

      it 'delegates to binary compiled content cache' do
        expect(binary).to have_received(meth).with(expect_args)
      end
    end

    describe '#prune' do
      let(:meth) { :prune }
      let(:args) { { items: [] } }

      include_context 'delegates to wrapped caches'
    end

    describe '#load' do
      let(:meth) { :load }
      let(:args) { nil }

      include_context 'delegates to wrapped caches'
    end

    describe '#store' do
      let(:meth) { :store }
      let(:args) { nil }

      include_context 'delegates to wrapped caches'
    end
  end
end
