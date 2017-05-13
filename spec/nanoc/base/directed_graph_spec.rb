# frozen_string_literal: true

describe Nanoc::Int::DirectedGraph do
  subject(:graph) { described_class.new([1, 2, 3]) }

  describe '#any_cycle' do
    subject { graph.any_cycle }

    context 'no cycles' do
      it { is_expected.to be_nil }
    end

    context 'one cycle without head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 1)
      end

      it { is_expected.to eq([1, 2]) }
    end

    context 'one cycle with head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 2)
      end

      it { is_expected.to eq([2, 3]) }
    end

    context 'one cycle with tail' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 20)
        graph.add_edge(20, 21)
        graph.add_edge(2, 3)
        graph.add_edge(3, 1)
      end

      it { is_expected.to eq([1, 2, 3]) }
    end

    context 'large cycle' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 4)
        graph.add_edge(4, 5)
        graph.add_edge(5, 1)
      end

      it { is_expected.to eq([1, 2, 3, 4, 5]) }
    end

    context 'large cycle with head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 4)
        graph.add_edge(4, 5)
        graph.add_edge(5, 2)
      end

      it { is_expected.to eq([2, 3, 4, 5]) }
    end
  end
end
