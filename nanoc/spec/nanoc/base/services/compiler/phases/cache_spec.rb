# frozen_string_literal: true

describe Nanoc::Int::Compiler::Phases::Cache do
  subject(:phase) do
    described_class.new(
      compiled_content_cache: compiled_content_cache,
      compiled_content_store: compiled_content_store,
      wrapped: wrapped,
    )
  end

  let(:compiled_content_cache) do
    Nanoc::Int::CompiledContentCache.new(config: config)
  end

  let(:compiled_content_store) { Nanoc::Int::CompiledContentStore.new }

  let(:wrapped_class) do
    Class.new(Nanoc::Int::Compiler::Phases::Abstract) do
      def initialize(compiled_content_store)
        @compiled_content_store = compiled_content_store
      end

      def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @compiled_content_store.set(rep, :last, Nanoc::Core::TextualContent.new('wrapped content'))
      end
    end
  end

  let(:wrapped) { wrapped_class.new(compiled_content_store) }

  let(:item) { Nanoc::Core::Item.new('item content', {}, '/donkey.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :latex) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe '#run' do
    subject { phase.call(rep, is_outdated: is_outdated) }

    let(:is_outdated) { raise 'override me' }

    before do
      rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: false)]

      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_started, anything, anything)
      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_yielded, anything, anything)
      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_resumed, anything, anything)
      allow(Nanoc::Core::NotificationCenter).to receive(:post).with(:phase_ended, anything, anything)
    end

    shared_examples 'calls wrapped' do
      it 'delegates to wrapped' do
        expect(wrapped).to receive(:run).with(rep, is_outdated: is_outdated)
        subject
      end

      it 'marks rep as compiled' do
        expect { subject }
          .to change { rep.compiled? }
          .from(false)
          .to(true)
      end

      it 'sends no other notifications' do
        subject
      end

      it 'updates compiled content cache' do
        expect { subject }
          .to change { compiled_content_cache[rep] }
          .from(nil)
          .to(last: some_textual_content('wrapped content'))
      end
    end

    context 'outdated' do
      let(:is_outdated) { true }
      include_examples 'calls wrapped'
    end

    context 'not outdated' do
      let(:is_outdated) { false }

      context 'textual cached compiled content available' do
        before do
          rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: false)]

          compiled_content_cache[rep] = { last: Nanoc::Core::TextualContent.new('cached') }
        end

        it 'reads content from cache' do
          expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .to change { compiled_content_store.get(rep, :last) }
            .from(nil)
            .to(some_textual_content('cached'))
        end

        it 'marks rep as compiled' do
          expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .to change { rep.compiled? }
            .from(false)
            .to(true)
        end

        it 'does not change compiled content cache' do
          expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .not_to change { compiled_content_cache[rep] }
        end
      end

      context 'binary cached compiled content available' do
        let(:binary_content) { 'b1n4ry' }
        let(:binary_filename) { Tempfile.open('test') { |fn| fn << binary_content }.path }

        before do
          rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: true)]

          compiled_content_cache[rep] = { last: Nanoc::Core::BinaryContent.new(binary_filename) }
        end

        it 'reads content from cache' do
          expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .to change { compiled_content_store.get(rep, :last) }
            .from(nil)
            .to(some_binary_content(binary_content))
        end

        it 'marks rep as compiled' do
          expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .to change { rep.compiled? }
            .from(false)
            .to(true)
        end

        it 'does not change compiled content cache' do
          expect(Nanoc::Core::NotificationCenter).to receive(:post).with(:cached_content_used, rep)

          expect { subject }
            .not_to change { compiled_content_cache[rep][:last].filename }
        end
      end

      context 'no cached compiled content available' do
        include_examples 'calls wrapped'
      end
    end
  end
end
