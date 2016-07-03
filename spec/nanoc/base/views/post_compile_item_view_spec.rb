describe Nanoc::PostCompileItemView do
  shared_examples 'a method that returns modified reps only' do
    let(:item) { Nanoc::Int::Item.new('blah', {}, '/foo.md') }
    let(:rep_a) { Nanoc::Int::ItemRep.new(item, :no_mod) }
    let(:rep_b) { Nanoc::Int::ItemRep.new(item, :modded).tap { |r| r.modified = true } }

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        reps << rep_a
        reps << rep_b
      end
    end

    let(:view_context) { double(:view_context, reps: reps) }
    let(:view) { described_class.new(item, view_context) }

    it 'returns only modified items' do
      expect(subject.size).to eq(1)
      expect(subject.map(&:name)).to eq(%i(modded))
    end

    it 'returns an array' do
      expect(subject.class).to eql(Array)
    end
  end

  describe '#modified_reps' do
    subject { view.modified_reps }
    it_behaves_like 'a method that returns modified reps only'
  end

  describe '#modified' do
    subject { view.modified }
    it_behaves_like 'a method that returns modified reps only'
  end
end
