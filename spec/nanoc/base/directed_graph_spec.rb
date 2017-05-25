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

  describe '#all_paths' do
    subject { graph.all_paths.to_a }

    context 'no cycles' do
      example do
        expect(subject).to contain_exactly(
          [1],
          [2],
          [3],
        )
      end
    end

    context 'one cycle without head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 1)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 1],
          [2],
          [2, 1],
          [2, 1, 2],
          [3],
        )
      end
    end

    context 'one cycle with head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 2)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 3],
          [1, 2, 3, 2],
          [2],
          [2, 3],
          [2, 3, 2],
          [3],
          [3, 2],
          [3, 2, 3],
        )
      end
    end

    context 'one cycle with tail' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 20)
        graph.add_edge(20, 21)
        graph.add_edge(2, 3)
        graph.add_edge(3, 1)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 20],
          [1, 2, 20, 21],
          [1, 2, 3],
          [1, 2, 3, 1],
          [2],
          [2, 20],
          [2, 20, 21],
          [2, 3],
          [2, 3, 1],
          [2, 3, 1, 2],
          [3],
          [3, 1],
          [3, 1, 2],
          [3, 1, 2, 20],
          [3, 1, 2, 20, 21],
          [3, 1, 2, 3],
          [20],
          [20, 21],
          [21],
        )
      end
    end

    context 'large cycle' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 4)
        graph.add_edge(4, 5)
        graph.add_edge(5, 1)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 3],
          [1, 2, 3, 4],
          [1, 2, 3, 4, 5],
          [1, 2, 3, 4, 5, 1],
          [2],
          [2, 3],
          [2, 3, 4],
          [2, 3, 4, 5],
          [2, 3, 4, 5, 1],
          [2, 3, 4, 5, 1, 2],
          [3],
          [3, 4],
          [3, 4, 5],
          [3, 4, 5, 1],
          [3, 4, 5, 1, 2],
          [3, 4, 5, 1, 2, 3],
          [4],
          [4, 5],
          [4, 5, 1],
          [4, 5, 1, 2],
          [4, 5, 1, 2, 3],
          [4, 5, 1, 2, 3, 4],
          [5],
          [5, 1],
          [5, 1, 2],
          [5, 1, 2, 3],
          [5, 1, 2, 3, 4],
          [5, 1, 2, 3, 4, 5],
        )
      end
    end

    context 'large cycle with head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 4)
        graph.add_edge(4, 5)
        graph.add_edge(5, 2)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 3],
          [1, 2, 3, 4],
          [1, 2, 3, 4, 5],
          [1, 2, 3, 4, 5, 2],
          [2],
          [2, 3],
          [2, 3, 4],
          [2, 3, 4, 5],
          [2, 3, 4, 5, 2],
          [3],
          [3, 4],
          [3, 4, 5],
          [3, 4, 5, 2],
          [3, 4, 5, 2, 3],
          [4],
          [4, 5],
          [4, 5, 2],
          [4, 5, 2, 3],
          [4, 5, 2, 3, 4],
          [5],
          [5, 2],
          [5, 2, 3],
          [5, 2, 3, 4],
          [5, 2, 3, 4, 5],
        )
      end
    end
  end

  describe '#dfs_from' do
    subject do
      [].tap do |ps|
        graph.dfs_from(1) do |p|
          ps << p
        end
      end
    end

    context 'no cycles' do
      example do
        expect(subject).to contain_exactly(
          [1],
        )
      end
    end

    context 'one cycle without head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 1)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 1],
        )
      end
    end

    context 'one cycle with head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 2)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 3],
          [1, 2, 3, 2],
        )
      end
    end

    context 'one cycle with tail' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 20)
        graph.add_edge(20, 21)
        graph.add_edge(2, 3)
        graph.add_edge(3, 1)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 20],
          [1, 2, 20, 21],
          [1, 2, 3],
          [1, 2, 3, 1],
        )
      end
    end

    context 'large cycle' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 4)
        graph.add_edge(4, 5)
        graph.add_edge(5, 1)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 3],
          [1, 2, 3, 4],
          [1, 2, 3, 4, 5],
          [1, 2, 3, 4, 5, 1],
        )
      end
    end

    context 'large cycle with head' do
      before do
        graph.add_edge(1, 2)
        graph.add_edge(2, 3)
        graph.add_edge(3, 4)
        graph.add_edge(4, 5)
        graph.add_edge(5, 2)
      end

      example do
        expect(subject).to contain_exactly(
          [1],
          [1, 2],
          [1, 2, 3],
          [1, 2, 3, 4],
          [1, 2, 3, 4, 5],
          [1, 2, 3, 4, 5, 2],
        )
      end
    end
  end
end
