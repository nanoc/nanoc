# frozen_string_literal: true

describe Nanoc::Int::DirectedGraph do
  subject(:graph) { described_class.new(%w[1 2 3]) }

  describe '#edges' do
    subject { graph.edges }

    context 'empty graph' do
      it { is_expected.to be_empty }
    end

    context 'graph with vertices, but no edges' do
      before do
        graph.add_vertex('1')
        graph.add_vertex('2')
      end

      it { is_expected.to be_empty }
    end

    context 'graph with edges from previously added vertices' do
      before do
        graph.add_vertex('1')
        graph.add_vertex('2')
        graph.add_vertex('3')

        graph.add_edge('1', '2')
        graph.add_edge('1', '3')
      end

      it { is_expected.to match_array([[0, 1, nil], [0, 2, nil]]) }
    end

    context 'graph with edges from new vertices' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('1', '3')
      end

      it { is_expected.to match_array([[0, 1, nil], [0, 2, nil]]) }
    end

    context 'graph with edge props' do
      before do
        graph.add_edge('1', '2', props: { name: 'Mr. C' })
        graph.add_edge('1', '3', props: { name: 'Cooper' })
      end

      it { is_expected.to match_array([[0, 1, { name: 'Mr. C' }], [0, 2, { name: 'Cooper' }]]) }
    end
  end

  describe '#props_for' do
    subject { graph.props_for('1', '2') }

    context 'no edge' do
      it { is_expected.to be_nil }
    end

    context 'edge, but no props' do
      before { graph.add_edge('1', '2') }
      it { is_expected.to be_nil }
    end

    context 'edge with props' do
      before { graph.add_edge('1', '2', props: { name: 'Mr. C' }) }
      it { is_expected.to eq(name: 'Mr. C') }

      context 'deleted edge (#delete_edges_to)' do
        before { graph.delete_edges_to('2') }
        it { is_expected.to be_nil }
      end
    end
  end

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
end
