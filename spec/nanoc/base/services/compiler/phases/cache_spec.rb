# frozen_string_literal: true

describe Nanoc::Int::Compiler::Phases::Cache do
  subject(:phase) do
    described_class.new(
      compiled_content_cache: compiled_content_cache,
      snapshot_repo: snapshot_repo,
      wrapped: wrapped,
    )
  end

  let(:compiled_content_cache) do
    Nanoc::Int::CompiledContentCache.new(items: [item])
  end

  let(:snapshot_repo) { Nanoc::Int::SnapshotRepo.new }

  let(:wrapped_class) do
    Class.new(Nanoc::Int::Compiler::Phases::Abstract) do
      def initialize(snapshot_repo)
        @snapshot_repo = snapshot_repo
      end

      def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @snapshot_repo.set(rep, :last, Nanoc::Int::TextualContent.new('wrapped content'))
      end
    end
  end

  let(:wrapped) { wrapped_class.new(snapshot_repo) }

  let(:item) { Nanoc::Int::Item.new('item content', {}, '/donkey.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :latex) }

  describe '#run' do
    subject { phase.call(rep, is_outdated: is_outdated) }

    let(:is_outdated) { raise 'override me' }

    before do
      allow(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_started, anything, anything)
      allow(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_yielded, anything, anything)
      allow(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_resumed, anything, anything)
      allow(Nanoc::Int::NotificationCenter).to receive(:post).with(:phase_ended, anything, anything)
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
          compiled_content_cache[rep] = { last: Nanoc::Int::TextualContent.new('cached') }
        end

        it 'writes content to cache' do
          expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .to change { snapshot_repo.get(rep, :last) }
            .from(nil)
            .to(some_textual_content('cached'))
        end

        it 'marks rep as compiled' do
          expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .to change { rep.compiled? }
            .from(false)
            .to(true)
        end

        it 'does not change compiled content cache' do
          expect(Nanoc::Int::NotificationCenter).to receive(:post).with(:cached_content_used, rep)
          expect { subject }
            .not_to change { compiled_content_cache[rep] }
        end
      end

      context 'binary cached compiled content available' do
        let(:binary_content) { 'b1n4ry' }
        let(:binary_filename) { Tempfile.open('test') { |fn| fn << binary_content }.path }

        before do
          compiled_content_cache[rep] = { last: Nanoc::Int::BinaryContent.new(binary_filename) }
        end

        it 'writes content to cache' do
          expect { subject }
            .to change { snapshot_repo.get(rep, :last) }
            .from(nil)
            .to(some_textual_content('wrapped content'))
        end

        it 'marks rep as compiled' do
          expect { subject }
            .to change { rep.compiled? }
            .from(false)
            .to(true)
        end

        it 'changes compiled content cache' do
          expect { subject }
            .to change { compiled_content_cache[rep] }
            .from(last: some_binary_content(binary_content))
            .to(last: some_textual_content('wrapped content'))
        end

        it 'does not send notification' do
          expect(Nanoc::Int::NotificationCenter).not_to receive(:post).with(:cached_content_used, rep)
          subject
        end
      end

      context 'no cached compiled content available' do
        include_examples 'calls wrapped'
      end
    end
  end
end
