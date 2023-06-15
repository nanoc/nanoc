# frozen_string_literal: true

describe Nanoc::Core::DirectedGraph do
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

      it { is_expected.to contain_exactly([0, 1, nil], [0, 2, nil]) }
    end

    context 'graph with edges from new vertices' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('1', '3')
      end

      it { is_expected.to contain_exactly([0, 1, nil], [0, 2, nil]) }
    end

    context 'graph with edge props' do
      before do
        graph.add_edge('1', '2', props: { name: 'Mr. C' })
        graph.add_edge('1', '3', props: { name: 'Cooper' })
      end

      it { is_expected.to contain_exactly([0, 1, { name: 'Mr. C' }], [0, 2, { name: 'Cooper' }]) }
    end
  end

  it 'has correct examples' do
    expect('Nanoc::Core::DirectedGraph')
      .to have_correct_yard_examples
      .in_file('nanoc-core/lib/nanoc/core/directed_graph.rb')
  end

  describe '#vertices' do
    subject { graph.vertices }

    it { is_expected.to include('1') }
    it { is_expected.not_to include('4') }
  end

  describe '#add_edge' do
    subject { graph.add_edge('1', '4') }

    it 'adds vertex' do
      expect { subject }
        .to change { graph.vertices.include?('4') }
        .from(false)
        .to(true)
    end

    it 'changes direct predecessors' do
      expect { subject }
        .to change { graph.direct_predecessors_of('4') }
        .from([])
        .to(['1'])
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

    context 'requested for non-existant vertex' do
      subject { graph.direct_predecessors_of('12345') }

      it { is_expected.to be_empty }
      it { is_expected.to be_a(Set) }
    end

    context 'one edge to' do
      before { graph.add_edge('1', '2') }

      it { is_expected.to contain_exactly('1') }
      it { is_expected.to be_a(Set) }
    end

    context 'two edges to' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('3', '2')
      end

      it { is_expected.to match_array(%w[1 3]) }
      it { is_expected.to be_a(Set) }
    end

    context 'edge from' do
      before { graph.add_edge('2', '3') }

      it { is_expected.to be_empty }
      it { is_expected.to be_a(Set) }
    end
  end

  describe '#predecessors_of' do
    subject { graph.predecessors_of('2') }

    context 'requested for non-existant vertex' do
      subject { graph.predecessors_of('12345') }

      it { is_expected.to be_empty }
      it { is_expected.to be_a(Set) }
    end

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
        it { is_expected.to contain_exactly('1') }
      end

      context 'indirect predecessors' do
        before { graph.add_edge('3', '1') }

        it { is_expected.to match_array(%w[1 2 3]) }
      end
    end
  end

  describe '#delete_edges_to' do
    subject { graph.delete_edges_to('1') }

    before do
      graph.add_edge('1', '2')
      graph.add_edge('2', '1')
      graph.add_edge('2', '3')
      graph.add_edge('3', '2')
      graph.add_edge('1', '3')
      graph.add_edge('3', '1')
    end

    it 'deletes edges to 1' do
      expect { subject }
        .to change { graph.direct_predecessors_of('1') }
        .from(%w[2 3])
        .to([])
    end

    it 'keeps edges to 2' do
      expect { subject }
        .not_to change { graph.direct_predecessors_of('2') }
    end

    it 'keeps edges to 3' do
      expect { subject }
        .not_to change { graph.direct_predecessors_of('3') }
    end

    it 'keeps edges to 4' do
      expect { subject }
        .not_to change { graph.direct_predecessors_of('4') }
    end
  end

  describe '#inspect' do
    subject { graph.inspect }

    context 'empty graph' do
      it { is_expected.to eq('Nanoc::Core::DirectedGraph()') }
    end

    context 'one edge, no props' do
      before do
        graph.add_edge('1', '2')
      end

      it { is_expected.to eq('Nanoc::Core::DirectedGraph("1" -> "2" props=nil)') }
    end

    context 'two edges, no props' do
      before do
        graph.add_edge('1', '2')
        graph.add_edge('2', '3')
      end

      it { is_expected.to eq('Nanoc::Core::DirectedGraph("1" -> "2" props=nil, "2" -> "3" props=nil)') }
    end

    context 'one edge, props' do
      before do
        graph.add_edge('1', '2', props: 'giraffe')
      end

      it { is_expected.to eq('Nanoc::Core::DirectedGraph("1" -> "2" props="giraffe")') }
    end

    context 'two edges, props' do
      before do
        graph.add_edge('1', '2', props: 'donkey')
        graph.add_edge('2', '3', props: 'zebra')
      end

      it { is_expected.to eq('Nanoc::Core::DirectedGraph("1" -> "2" props="donkey", "2" -> "3" props="zebra")') }
    end
  end
end
