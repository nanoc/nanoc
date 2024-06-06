# frozen_string_literal: true

require_relative 'support/item_rep_view_examples'

describe Nanoc::Core::PostCompileItemRepView do
  let(:expected_item_view_class) { Nanoc::Core::PostCompileItemView }

  let(:compiled_content_cache) do
    # Pretend binary snapshots exist on disk so the binary cache can cache them.
    snapshot_contents
      .select { |_, content| content.binary? }
      .each do |_, binary_content|
        allow(FileUtils).to receive(:cp).with(binary_content.filename, anything)
                                        .and_wrap_original do |_meth, _src, dst|
          File.new(dst, 'w').close
        end
      end

    Nanoc::Core::CompiledContentCache.new(config:).tap do |ccc|
      ccc[item_rep] = snapshot_contents
    end
  end

  let(:snapshot_contents) do
    {
      last: Nanoc::Core::TextualContent.new('content-last'),
      pre: Nanoc::Core::TextualContent.new('content-pre'),
      donkey: Nanoc::Core::TextualContent.new('content-donkey'),
    }
  end

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(double(:dependency_store)) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker:,
      compilation_context:,
      compiled_content_store:,
    )
  end

  let(:view) { described_class.new(item_rep, view_context) }
  let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }

  let(:item_rep) do
    Nanoc::Core::ItemRep.new(item, :jacques).tap do |rep|
      rep.snapshot_defs = snapshot_contents.map do |name, content|
        Nanoc::Core::SnapshotDef.new(name, binary: content.binary?)
      end
    end
  end

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
    )
  end

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  it_behaves_like 'an item rep view'

  describe '#raw_path' do
    context 'no args' do
      subject { view.raw_path }

      it 'does not raise' do # rubocop:disable RSpec/NoExpectationExample
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

      it 'does not raise' do # rubocop:disable RSpec/NoExpectationExample
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
        temp_file = Tempfile.new('binary junk')
        temp_file.write('binary data here')
        temp_file.sync

        {
          last: Nanoc::Core::TextualContent.new('content-last'),
          pre: Nanoc::Core::BinaryContent.new(temp_file.path),
          donkey: Nanoc::Core::TextualContent.new('content-donkey'),
        }
      end

      it 'raises error' do
        expect { subject }.to raise_error(Nanoc::Core::Errors::CannotGetCompiledContentOfBinaryItem, 'You cannot access the compiled content of a binary item representation (but you can access the path). The offending item rep is /foo (rep name :jacques).')
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
        err = Nanoc::Core::Errors::NoSuchSnapshot
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
