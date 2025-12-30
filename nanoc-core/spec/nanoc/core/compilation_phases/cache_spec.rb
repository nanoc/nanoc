# frozen_string_literal: true

describe Nanoc::Core::CompilationPhases::Cache do
  subject(:phase) do
    described_class.new(
      compiled_content_cache:,
      compiled_content_repo:,
      wrapped:,
    )
  end

  let(:compiled_content_cache) do
    Nanoc::Core::CompiledContentCache.new(config:)
  end

  let(:compiled_content_repo) { Nanoc::Core::CompiledContentRepo.new }

  let(:wrapped_class) do
    Class.new(Nanoc::Core::CompilationPhases::Abstract) do
      def initialize(compiled_content_repo)
        @compiled_content_repo = compiled_content_repo
      end

      def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @compiled_content_repo.set(rep, :last, Nanoc::Core::TextualContent.new('wrapped content'))
      end
    end
  end

  let(:wrapped) { wrapped_class.new(compiled_content_repo) }

  let(:item) { Nanoc::Core::Item.new('item content', {}, '/donkey.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :latex) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe '#run' do
    subject { phase.call(rep, is_outdated:) }

    let(:is_outdated) { false } # NOTE: not used

    before do
      rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: false)]

      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_started, anything, anything)
      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_yielded, anything, anything)
      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_resumed, anything, anything)
      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_ended, anything, anything)
    end

    context 'when already compiled' do
      before { rep.compiled = true }

      it 'does not call wrapped' do
        expect(wrapped).not_to receive(:run).with(rep, is_outdated:)
        subject
      end
    end

    context 'when not yet compiled' do
      it 'delegates to wrapped' do
        expect(wrapped).to receive(:run).with(rep, is_outdated:)
        subject
      end

      it 'sends no other notifications' do # rubocop:disable RSpec/NoExpectationExample
        subject
      end

      it 'updates compiled content cache' do
        expect { subject }
          .to change { compiled_content_cache[rep] }
          .from(nil)
          .to(last: some_textual_content('wrapped content'))
      end

      it 'marks rep as compiled' do
        expect { subject }
          .to change(rep, :compiled?)
          .from(false)
          .to(true)
      end
    end
  end
end
