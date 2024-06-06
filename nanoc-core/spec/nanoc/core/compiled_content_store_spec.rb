# frozen_string_literal: true

describe Nanoc::Core::CompiledContentStore do
  subject(:repo) { described_class.new }

  describe '#get' do
    subject { repo.get(rep, snapshot_name) }

    let(:item) { Nanoc::Core::Item.new('contentz', {}, '/foo.md') }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :foo) }
    let(:snapshot_name) { :donkey }

    context 'rep does not exist in repo' do
      it { is_expected.to be_nil }
    end

    context 'rep exists in repo' do
      before { repo.set(rep, :foobar, Nanoc::Core::TextualContent.new('other content')) }

      context 'snapshot does not exist in repo' do
        it { is_expected.to be_nil }
      end

      context 'snapshot exists in repo' do
        before { repo.set(rep, :donkey, Nanoc::Core::TextualContent.new('donkey')) }

        it { is_expected.to be_some_textual_content('donkey') }
      end
    end
  end

  describe '#get_all' do
    subject { repo.get_all(rep) }

    let(:item) { Nanoc::Core::Item.new('contentz', {}, '/foo.md') }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :foo) }

    context 'rep does not exist in repo' do
      it { is_expected.to eq({}) }
    end

    context 'rep exists in repo' do
      before { repo.set(rep, :foobar, Nanoc::Core::TextualContent.new('donkey')) }

      it { is_expected.to match(foobar: some_textual_content('donkey')) }
    end
  end

  describe '#set' do
    subject { repo.set(rep, snapshot_name, contents) }

    let(:item) { Nanoc::Core::Item.new('contentz', {}, '/foo.md') }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :foo) }
    let(:snapshot_name) { :donkey }
    let(:contents) { Nanoc::Core::TextualContent.new('donkey') }

    it 'changes the given rep+snapshot' do
      expect { subject }
        .to change { repo.get(rep, snapshot_name) }
        .from(nil)
        .to(some_textual_content('donkey'))
    end
  end

  describe '#set_all' do
    subject { repo.set_all(rep, contents_by_snapshot) }

    let(:other_item) { Nanoc::Core::Item.new('contentz', {}, '/foo2.md') }
    let(:other_rep) { Nanoc::Core::ItemRep.new(other_item, :foo) }

    let(:item) { Nanoc::Core::Item.new('contentz', {}, '/foo.md') }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :foo) }
    let(:contents_by_snapshot) { { donkey: Nanoc::Core::TextualContent.new('donkey') } }

    it 'changes the given rep+snapshot' do
      expect { subject }
        .to change { repo.get(rep, :donkey) }
        .from(nil)
        .to(some_textual_content('donkey'))
    end

    it 'leaves other reps intact' do
      expect { subject }
        .not_to change { repo.get(other_rep, :donkey) }
    end

    it 'leaves other snapshots intact' do
      expect { subject }
        .not_to change { repo.get(rep, :giraffe) }
    end
  end

  describe '#compiled_content' do
    let(:item) { Nanoc::Core::Item.new('contentz', {}, '/foo.md') }
    let(:rep) { Nanoc::Core::ItemRep.new(item, :foo) }

    shared_examples 'a snapshot' do
      context 'no snapshot def' do
        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Core::Errors::NoSuchSnapshot)
        end
      end

      context 'snapshot def exists' do
        context 'content is missing' do
          before do
            rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(expected_snapshot_name, binary: false)]
            repo.set_all(rep, {})
          end

          it 'errors' do
            expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Core::Errors::UnmetDependency))
          end
        end

        context 'content is present' do
          before do
            rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(expected_snapshot_name, binary: false)]
            repo.set_all(rep, expected_snapshot_name => content)
          end

          context 'content is textual' do
            let(:content) { Nanoc::Core::TextualContent.new('hellos') }

            it { is_expected.to eql('hellos') }
          end

          context 'content is binary' do
            before { File.write('donkey.dat', 'binary data') }

            let(:content) { Nanoc::Core::BinaryContent.new(File.expand_path('donkey.dat')) }

            it 'raises' do
              expect { subject }.to raise_error(Nanoc::Core::Errors::CannotGetCompiledContentOfBinaryItem, 'You cannot access the compiled content of a binary item representation (but you can access the path). The offending item rep is /foo.md (rep name :foo).')
            end
          end
        end
      end
    end

    context 'snapshot nil' do
      subject { repo.compiled_content(rep:, snapshot: nil) }

      let(:expected_snapshot_name) { :last }

      include_examples 'a snapshot'

      context 'when :pre and :last snapshot definitions exist' do
        before do
          rep.snapshot_defs = [
            Nanoc::Core::SnapshotDef.new(:pre, binary: false),
            Nanoc::Core::SnapshotDef.new(:last, binary: false),
          ]
        end

        context 'when :last, but no :pre content is available' do
          before do
            content = Nanoc::Core::TextualContent.new('hellos')
            repo.set_all(rep, last: content)
          end

          it 'does not use :last' do
            expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Core::Errors::UnmetDependency))
          end
        end
      end
    end

    context 'snapshot not specified' do
      subject { repo.compiled_content(rep:) }

      let(:expected_snapshot_name) { :last }

      include_examples 'a snapshot'

      context 'when :pre and :last snapshot definitions exist' do
        before do
          rep.snapshot_defs = [
            Nanoc::Core::SnapshotDef.new(:pre, binary: false),
            Nanoc::Core::SnapshotDef.new(:last, binary: false),
          ]
        end

        context 'when :last, but no :pre content is available' do
          before do
            content = Nanoc::Core::TextualContent.new('hellos')
            repo.set_all(rep, last: content)
          end

          it 'does not use :last' do
            expect { subject }.to yield_from_fiber(an_instance_of(Nanoc::Core::Errors::UnmetDependency))
          end
        end
      end
    end

    context 'snapshot :pre specified' do
      subject { repo.compiled_content(rep:, snapshot: :pre) }

      let(:expected_snapshot_name) { :pre }

      include_examples 'a snapshot'
    end

    context 'snapshot :post specified' do
      subject { repo.compiled_content(rep:, snapshot: :post) }

      let(:expected_snapshot_name) { :post }

      include_examples 'a snapshot'
    end

    context 'snapshot :last specified' do
      subject { repo.compiled_content(rep:, snapshot: :last) }

      let(:expected_snapshot_name) { :last }

      include_examples 'a snapshot'
    end

    context 'snapshot :donkey specified' do
      subject { repo.compiled_content(rep:, snapshot: :donkey) }

      let(:expected_snapshot_name) { :donkey }

      include_examples 'a snapshot'
    end
  end
end
