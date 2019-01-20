# frozen_string_literal: true

require_relative 'support/item_rep_view_examples'

describe Nanoc::PostCompileItemRepView do
  let(:expected_item_view_class) { Nanoc::PostCompileItemView }

  it_behaves_like 'an item rep view'

  let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
  let(:view) { described_class.new(item_rep, view_context) }

  let(:view_context) do
    Nanoc::ViewContextForCompilation.new(
      reps: Nanoc::Int::ItemRepRepo.new,
      items: Nanoc::Int::ItemCollection.new(config),
      dependency_tracker: dependency_tracker,
      compilation_context: compilation_context,
      compiled_content_store: compiled_content_store,
    )
  end

  let(:reps) { double(:reps) }
  let(:items) { Nanoc::Int::ItemCollection.new(config) }
  let(:config) { Nanoc::Int::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }
  let(:compilation_context) { double(:compilation_context, compiled_content_cache: compiled_content_cache) }
  let(:compiled_content_store) { double(:compiled_content_store) }

  let(:snapshot_contents) do
    {
      last: Nanoc::Core::TextualContent.new('content-last'),
      pre: Nanoc::Core::TextualContent.new('content-pre'),
      donkey: Nanoc::Core::TextualContent.new('content-donkey'),
    }
  end

  let(:compiled_content_cache) do
    Nanoc::Int::CompiledContentCache.new(config: config).tap do |ccc|
      ccc[item_rep] = snapshot_contents
    end
  end

  describe '#raw_path' do
    context 'no args' do
      subject { view.raw_path }

      it 'does not raise' do
        subject
      end

      context 'no path specified' do
        it { is_expected.to be_nil }
      end

      context 'path for default snapshot specified' do
        before do
          item_rep.raw_paths = { last: [Dir.getwd + '/output/about/index.html'] }
        end

        it { is_expected.to eql(Dir.getwd + '/output/about/index.html') }
      end

      context 'path specified, but not for default snapshot' do
        before do
          item_rep.raw_paths = { pre: [Dir.getwd + '/output/about/index.html'] }
        end

        it { is_expected.to be_nil }
      end
    end

    context 'snapshot arg' do
      subject { view.raw_path(snapshot: :special) }

      it 'does not raise' do
        subject
      end

      context 'no path specified' do
        it { is_expected.to be_nil }
      end

      context 'path for default snapshot specified' do
        before do
          item_rep.raw_paths = { special: [Dir.getwd + '/output/about/index.html'] }
        end

        it { is_expected.to eql(Dir.getwd + '/output/about/index.html') }
      end

      context 'path specified, but not for default snapshot' do
        before do
          item_rep.raw_paths = { pre: [Dir.getwd + '/output/about/index.html'] }
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#compiled_content' do
    subject { view.compiled_content }

    context 'binary' do
      let(:snapshot_contents) do
        {
          last: Nanoc::Core::TextualContent.new('content-last'),
          pre: Nanoc::Core::BinaryContent.new('/content/pre'),
          donkey: Nanoc::Core::TextualContent.new('content-donkey'),
        }
      end

      it 'raises error' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem, 'You cannot access the compiled content of a binary item representation (but you can access the path). The offending item rep is /foo (rep name :jacques).')
      end
    end

    shared_examples 'returns pre content' do
      example { expect(subject).to eq('content-pre') }
    end

    shared_examples 'returns last content' do
      example { expect(subject).to eq('content-last') }
    end

    shared_examples 'returns donkey content' do
      example { expect(subject).to eq('content-donkey') }
    end

    shared_examples 'raises no-such-snapshot error' do
      it 'raises error' do
        err = Nanoc::Int::Errors::NoSuchSnapshot
        expect { subject }.to raise_error(err)
      end
    end

    context 'textual' do
      context 'snapshot provided' do
        subject { view.compiled_content(snapshot: :donkey) }
        let(:expected_snapshot) { :donkey }

        context 'snapshot exists' do
          include_examples 'returns donkey content'
        end

        context 'snapshot does not exist' do
          let(:snapshot_contents) do
            {
              last: Nanoc::Core::TextualContent.new('content-last'),
              pre: Nanoc::Core::TextualContent.new('content-pre'),
            }
          end

          include_examples 'raises no-such-snapshot error'
        end
      end

      context 'no snapshot provided' do
        context 'pre and last snapshots exist' do
          let(:snapshot_contents) do
            {
              last: Nanoc::Core::TextualContent.new('content-last'),
              pre: Nanoc::Core::TextualContent.new('content-pre'),
              donkey: Nanoc::Core::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'returns pre content'
        end

        context 'pre snapshot exists' do
          let(:snapshot_contents) do
            {
              pre: Nanoc::Core::TextualContent.new('content-pre'),
              donkey: Nanoc::Core::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'returns pre content'
        end

        context 'last snapshot exists' do
          let(:snapshot_contents) do
            {
              last: Nanoc::Core::TextualContent.new('content-last'),
              donkey: Nanoc::Core::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'returns last content'
        end

        context 'neither pre nor last snapshot exists' do
          let(:snapshot_contents) do
            {
              donkey: Nanoc::Core::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'raises no-such-snapshot error'
        end
      end
    end
  end
end
