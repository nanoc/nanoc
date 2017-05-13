# frozen_string_literal: true

describe Nanoc::PostCompileItemRepView do
  let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
  let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo/') }
  let(:view) { described_class.new(item_rep, view_context) }

  let(:view_context) do
    Nanoc::ViewContext.new(
      reps: reps,
      items: items,
      dependency_tracker: dependency_tracker,
      compilation_context: compilation_context,
      snapshot_repo: snapshot_repo,
    )
  end

  let(:reps) { double(:reps) }
  let(:items) { Nanoc::Int::IdentifiableCollection.new(config) }
  let(:config) { Nanoc::Int::Configuration.new }
  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }
  let(:compilation_context) { double(:compilation_context, compiled_content_cache: compiled_content_cache) }
  let(:snapshot_repo) { double(:snapshot_repo) }

  let(:snapshot_contents) do
    {
      last: Nanoc::Int::TextualContent.new('content-last'),
      pre: Nanoc::Int::TextualContent.new('content-pre'),
      donkey: Nanoc::Int::TextualContent.new('content-donkey'),
    }
  end

  let(:compiled_content_cache) do
    Nanoc::Int::CompiledContentCache.new(items: items).tap do |ccc|
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
          item_rep.raw_paths = { last: ['output/about/index.html'] }
        end

        it { is_expected.to eql('output/about/index.html') }
      end

      context 'path specified, but not for default snapshot' do
        before do
          item_rep.raw_paths = { pre: ['output/about/index.html'] }
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
          item_rep.raw_paths = { special: ['output/about/index.html'] }
        end

        it { is_expected.to eql('output/about/index.html') }
      end

      context 'path specified, but not for default snapshot' do
        before do
          item_rep.raw_paths = { pre: ['output/about/index.html'] }
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
          last: Nanoc::Int::TextualContent.new('content-last'),
          pre: Nanoc::Int::BinaryContent.new('/content/pre'),
          donkey: Nanoc::Int::TextualContent.new('content-donkey'),
        }
      end

      it 'raises error' do
        err = Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem
        expect { subject }.to raise_error(err)
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
              last: Nanoc::Int::TextualContent.new('content-last'),
              pre: Nanoc::Int::TextualContent.new('content-pre'),
            }
          end

          include_examples 'raises no-such-snapshot error'
        end
      end

      context 'no snapshot provided' do
        context 'pre and last snapshots exist' do
          let(:snapshot_contents) do
            {
              last: Nanoc::Int::TextualContent.new('content-last'),
              pre: Nanoc::Int::TextualContent.new('content-pre'),
              donkey: Nanoc::Int::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'returns pre content'
        end

        context 'pre snapshot exists' do
          let(:snapshot_contents) do
            {
              pre: Nanoc::Int::TextualContent.new('content-pre'),
              donkey: Nanoc::Int::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'returns pre content'
        end

        context 'last snapshot exists' do
          let(:snapshot_contents) do
            {
              last: Nanoc::Int::TextualContent.new('content-last'),
              donkey: Nanoc::Int::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'returns last content'
        end

        context 'neither pre nor last snapshot exists' do
          let(:snapshot_contents) do
            {
              donkey: Nanoc::Int::TextualContent.new('content-donkey'),
            }
          end

          include_examples 'raises no-such-snapshot error'
        end
      end
    end
  end
end
