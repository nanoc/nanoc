# frozen_string_literal: true

describe Nanoc::Int::ItemRep do
  let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :giraffe) }

  describe '#snapshot?' do
    subject { rep.snapshot?(snapshot_name) }

    let(:snapshot_name) { raise 'override me' }

    before do
      rep.snapshot_defs = [Nanoc::Int::SnapshotDef.new(:donkey, binary: false)]
    end

    context 'snapshot does not exist' do
      let(:snapshot_name) { :giraffe }
      it { is_expected.not_to be }
    end

    context 'snapshot exists' do
      let(:snapshot_name) { :donkey }
      it { is_expected.to be }
    end
  end
end
