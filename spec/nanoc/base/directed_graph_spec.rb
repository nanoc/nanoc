# frozen_string_literal: true

describe Nanoc::Int::DirectedGraph do
  subject(:graph) { described_class.new(%w[1 2 3]) }

  describe '#direct_predecessors_of' do
    subject { graph.direct_predecessors_of('2') }

    context 'no edges' do
      it { is_expected.to be_empty }
    end

    context 'one edge to' do
      before { graph.add_edge('1', '2') }
      it { is_expected.to eq(['1']) }
    end

    context 'two edges to' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('3', '2')
      end

      it { is_expected.to match_array(%w[1 3]) }
    end

    context 'edge from' do
      before { graph.add_edge('2', '3') }
      it { is_expected.to be_empty }
    end
  end

  describe '#direct_successors_of' do
    subject { graph.direct_successors_of('2') }

    context 'no edges' do
      it { is_expected.to be_empty }
    end

    context 'one edge to' do
      before { graph.add_edge('1', '2') }
      it { is_expected.to be_empty }
    end

    context 'one edge from' do
      before { graph.add_edge('2', '3') }
      it { is_expected.to eq(['3']) }
    end

    context 'two edges from' do
      before do
        graph.add_edge('2', '1')
        graph.add_edge('2', '3')
      end

      it { is_expected.to match_array(%w[1 3]) }
    end
  end

  describe '#predecessors_of' do
    subject { graph.predecessors_of('2') }

    context 'no predecessors' do
      before do
        graph.add_edge('2', '3')
      end

      it { is_expected.to be_empty }
    end

    context 'direct predecessor' do
      before do
        graph.add_edge('2', '3')
        graph.add_edge('1', '2')
      end

      context 'no indirect predecessors' do
        it { is_expected.to match_array(['1']) }
      end

      context 'indirect predecessors' do
        before { graph.add_edge('3', '1') }
        it { is_expected.to match_array(%w[1 2 3]) }
      end
    end
  end

  describe '#successors_of' do
    subject { graph.successors_of('2') }

    context 'no successors' do
      before do
        graph.add_edge('1', '2')
      end

      it { is_expected.to be_empty }
    end

    context 'direct predecessor' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
      end

      context 'no indirect successors' do
        it { is_expected.to match_array(['3']) }
      end

      context 'indirect successors' do
        before { graph.add_edge('3', '1') }
        it { is_expected.to match_array(%w[1 2 3]) }
      end
    end
  end

  describe '#inspect' do
    subject { graph.inspect }

    context 'empty graph' do
      it { is_expected.to eq('Nanoc::Int::DirectedGraph()') }
    end

    context 'one edge, no props' do
      before do
        graph.add_edge('1', '2')
      end

      it { is_expected.to eq('Nanoc::Int::DirectedGraph("1" -> "2" props=nil)') }
    end

    context 'two edges, no props' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
      end

      it { is_expected.to eq('Nanoc::Int::DirectedGraph("1" -> "2" props=nil, "2" -> "3" props=nil)') }
    end

    context 'one edge, props' do
      before do
        graph.add_edge('1', '2', props: 'giraffe')
      end

      it { is_expected.to eq('Nanoc::Int::DirectedGraph("1" -> "2" props="giraffe")') }
    end

    context 'two edges, props' do
      before do
        graph.add_edge('1', '2', props: 'donkey')
        graph.add_edge('2', '3', props: 'zebra')
      end

      it { is_expected.to eq('Nanoc::Int::DirectedGraph("1" -> "2" props="donkey", "2" -> "3" props="zebra")') }
    end
  end

  describe '#any_cycle' do
    subject { graph.any_cycle }

    context 'no cycles' do
      it { is_expected.to be_nil }
    end

    context 'one cycle without head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '1')
      end

      it { is_expected.to eq(%w[1 2]) }
    end

    context 'one cycle with head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '2')
      end

      it { is_expected.to eq(%w[2 3]) }
    end

    context 'one cycle with tail' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '20')
        graph.add_edge('20', '21')
        graph.add_edge('2', '3')
        graph.add_edge('3', '1')
      end

      it { is_expected.to eq(%w[1 2 3]) }
    end

    context 'large cycle' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '4')
        graph.add_edge('4', '5')
        graph.add_edge('5', '1')
      end

      it { is_expected.to eq(%w[1 2 3 4 5]) }
    end

    context 'large cycle with head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '4')
        graph.add_edge('4', '5')
        graph.add_edge('5', '2')
      end

      it { is_expected.to eq(%w[2 3 4 5]) }
    end
  end

  describe '#all_paths' do
    subject { graph.all_paths.to_a }

    context 'no cycles' do
      example do
        expect(subject).to contain_exactly(
          ['1'],
          ['2'],
          ['3'],
        )
      end
    end

    context 'one cycle without head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '1')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 1],
          ['2'],
          %w[2 1],
          %w[2 1 2],
          ['3'],
        )
      end
    end

    context 'one cycle with head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '2')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 3],
          %w[1 2 3 2],
          ['2'],
          %w[2 3],
          %w[2 3 2],
          ['3'],
          %w[3 2],
          %w[3 2 3],
        )
      end
    end

    context 'one cycle with tail' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '20')
        graph.add_edge('20', '21')
        graph.add_edge('2', '3')
        graph.add_edge('3', '1')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 20],
          %w[1 2 20 21],
          %w[1 2 3],
          %w[1 2 3 1],
          ['2'],
          %w[2 20],
          %w[2 20 21],
          %w[2 3],
          %w[2 3 1],
          %w[2 3 1 2],
          ['3'],
          %w[3 1],
          %w[3 1 2],
          %w[3 1 2 20],
          %w[3 1 2 20 21],
          %w[3 1 2 3],
          ['20'],
          %w[20 21],
          ['21'],
        )
      end
    end

    context 'large cycle' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '4')
        graph.add_edge('4', '5')
        graph.add_edge('5', '1')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 3],
          %w[1 2 3 4],
          %w[1 2 3 4 5],
          %w[1 2 3 4 5 1],
          ['2'],
          %w[2 3],
          %w[2 3 4],
          %w[2 3 4 5],
          %w[2 3 4 5 1],
          %w[2 3 4 5 1 2],
          ['3'],
          %w[3 4],
          %w[3 4 5],
          %w[3 4 5 1],
          %w[3 4 5 1 2],
          %w[3 4 5 1 2 3],
          ['4'],
          %w[4 5],
          %w[4 5 1],
          %w[4 5 1 2],
          %w[4 5 1 2 3],
          %w[4 5 1 2 3 4],
          ['5'],
          %w[5 1],
          %w[5 1 2],
          %w[5 1 2 3],
          %w[5 1 2 3 4],
          %w[5 1 2 3 4 5],
        )
      end
    end

    context 'large cycle with head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '4')
        graph.add_edge('4', '5')
        graph.add_edge('5', '2')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 3],
          %w[1 2 3 4],
          %w[1 2 3 4 5],
          %w[1 2 3 4 5 2],
          ['2'],
          %w[2 3],
          %w[2 3 4],
          %w[2 3 4 5],
          %w[2 3 4 5 2],
          ['3'],
          %w[3 4],
          %w[3 4 5],
          %w[3 4 5 2],
          %w[3 4 5 2 3],
          ['4'],
          %w[4 5],
          %w[4 5 2],
          %w[4 5 2 3],
          %w[4 5 2 3 4],
          ['5'],
          %w[5 2],
          %w[5 2 3],
          %w[5 2 3 4],
          %w[5 2 3 4 5],
        )
      end
    end
  end

  describe '#dfs_from' do
    subject do
      [].tap do |ps|
        graph.dfs_from('1') do |p|
          ps << p
        end
      end
    end

    context 'no cycles' do
      example do
        expect(subject).to contain_exactly(
          ['1'],
        )
      end
    end

    context 'one cycle without head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '1')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 1],
        )
      end
    end

    context 'one cycle with head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '2')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 3],
          %w[1 2 3 2],
        )
      end
    end

    context 'one cycle with tail' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '20')
        graph.add_edge('20', '21')
        graph.add_edge('2', '3')
        graph.add_edge('3', '1')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 20],
          %w[1 2 20 21],
          %w[1 2 3],
          %w[1 2 3 1],
        )
      end
    end

    context 'large cycle' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '4')
        graph.add_edge('4', '5')
        graph.add_edge('5', '1')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 3],
          %w[1 2 3 4],
          %w[1 2 3 4 5],
          %w[1 2 3 4 5 1],
        )
      end
    end

    context 'large cycle with head' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
        graph.add_edge('3', '4')
        graph.add_edge('4', '5')
        graph.add_edge('5', '2')
      end

      example do
        expect(subject).to contain_exactly(
          ['1'],
          %w[1 2],
          %w[1 2 3],
          %w[1 2 3 4],
          %w[1 2 3 4 5],
          %w[1 2 3 4 5 2],
        )
      end
    end
  end
end
