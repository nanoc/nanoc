# frozen_string_literal: true

describe Nanoc::Core::CompilationStages::DetermineOutdatedness do
  let(:stage) do
    described_class.new(
      reps:,
      outdatedness_checker:,
      outdatedness_store:,
    )
  end

  let(:reps) do
    Nanoc::Core::ItemRepRepo.new
  end

  let(:outdatedness_checker) do
    double(:outdatedness_checker)
  end

  let(:outdatedness_store) do
    Nanoc::Core::OutdatednessStore.new(config:)
  end

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:code_snippets) { [] }

  describe '#run' do
    subject { stage.run }

    context 'outdatedness store is empty' do
      let(:item) do
        Nanoc::Core::Item.new('', {}, '/hi.md')
      end

      let(:rep) do
        Nanoc::Core::ItemRep.new(item, :woof)
      end

      let(:other_rep) do
        Nanoc::Core::ItemRep.new(item, :bark)
      end

      context 'outdatedness checker thinks rep is outdated' do
        before do
          reps << rep
          reps << other_rep

          expect(outdatedness_checker)
            .to receive(:outdatedness_reasons_for).with(rep).and_return([double])

          expect(outdatedness_checker)
            .to receive(:outdatedness_reasons_for).with(other_rep).and_return([])
        end

        it 'adds the rep' do
          expect { subject }
            .to change { outdatedness_store.include?(rep) }
            .from(false)
            .to(true)
        end

        it 'also adds the other rep' do
          expect { subject }
            .to change { outdatedness_store.include?(other_rep) }
            .from(false)
            .to(true)
        end

        it 'returns a list with the known rep’s item' do
          expect(subject).to eq([rep.item])
        end
      end

      context 'outdatedness checker thinks rep is not outdated' do
        it 'keeps the outdatedness store empty' do
          expect { subject }
            .not_to change(outdatedness_store, :empty?)
        end

        it 'returns an empty list' do
          expect(subject).to be_empty
        end
      end
    end

    context 'outdatedness store contains known rep' do
      let(:item) do
        Nanoc::Core::Item.new('', {}, '/hi.md')
      end

      let(:rep) do
        Nanoc::Core::ItemRep.new(item, :woof)
      end

      let(:other_rep) do
        Nanoc::Core::ItemRep.new(item, :bark)
      end

      before do
        reps << rep
        reps << other_rep

        outdatedness_store.add(rep)

        expect(outdatedness_checker)
          .to receive(:outdatedness_reasons_for).with(other_rep).and_return([])
      end

      it 'keeps the rep' do
        expect { subject }
          .not_to change { outdatedness_store.include?(rep) }
      end

      it 'also adds the other rep' do
        expect { subject }
          .to change { outdatedness_store.include?(other_rep) }
          .from(false)
          .to(true)
      end

      it 'returns a list with the known rep’s item' do
        expect(subject).to eq([rep.item])
      end
    end

    context 'outdatedness store contains unknown rep' do
      let(:item) do
        Nanoc::Core::Item.new('', {}, '/hi.md')
      end

      let(:unknown_rep) do
        Nanoc::Core::ItemRep.new(item, :woof)
      end

      before do
        outdatedness_store.add(unknown_rep)
      end

      it 'removes the unknown rep' do
        expect { subject }
          .to change { outdatedness_store.include?(unknown_rep) }
          .from(true)
          .to(false)
      end

      it 'returns an empty list' do
        expect(subject).to be_empty
      end
    end
  end
end
