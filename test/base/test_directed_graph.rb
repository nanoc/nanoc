# frozen_string_literal: true

require 'helper'

class Nanoc::Int::DirectedGraphTest < Nanoc::TestCase
  def test_add_edge
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])

    assert_equal [], graph.predecessors_of(2).to_a

    graph.add_edge(1, 2)

    assert_equal [1], graph.predecessors_of(2).to_a
  end

  def test_add_edge_with_new_vertices
    graph = Nanoc::Int::DirectedGraph.new([1])
    graph.add_edge(1, 2)
    graph.add_edge(3, 2)

    assert graph.vertices.include?(2)
    assert graph.vertices.include?(3)
  end

  def test_delete_edges_to
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])

    graph.add_edge(1, 2)
    graph.add_edge(2, 1)
    graph.add_edge(2, 3)
    graph.add_edge(3, 2)
    graph.add_edge(1, 3)
    graph.add_edge(3, 1)

    assert_equal [2, 3], graph.direct_predecessors_of(1).sort
    assert_equal [1, 3], graph.direct_predecessors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort

    graph.delete_edges_to(1)

    assert_equal [], graph.direct_predecessors_of(1).sort
    assert_equal [1, 3], graph.direct_predecessors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort

    graph.delete_edges_to(2)

    assert_equal [], graph.direct_predecessors_of(1).sort
    assert_equal [], graph.direct_predecessors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort
  end

  def test_example
    YARD.parse(LIB_DIR + '/nanoc/base/entities/directed_graph.rb')
    assert_examples_correct 'Nanoc::Int::DirectedGraph'
  end
end
