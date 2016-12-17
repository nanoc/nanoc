describe Nanoc::PostCompileItemRepView do
  let(:item_rep) { Nanoc::Int::ItemRep.new(item, :jacques) }
  let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo/') }
  let(:view) { described_class.new(item_rep, view_context) }

  let(:view_context) do
    Nanoc::ViewContext.new(
      reps: reps,
      items: items,
      dependency_tracker: dependency_tracker,
      compiler: compiler,
    )
  end

  let(:reps) { double(:reps) }
  let(:items) { double(:items) }
  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(double(:dependency_store)) }
  let(:compiler) { double(:compiler, compiled_content_cache: compiled_content_cache) }

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

  describe '#compiled_content' do
    subject { view.compiled_content }

    context 'binary' do
      let(:item) do
        content = Nanoc::Int::Content.create('/foo.dat', binary: true)
        Nanoc::Int::Item.new(content, {}, '/foo.dat')
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
