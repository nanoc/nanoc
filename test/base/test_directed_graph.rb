# encoding: utf-8

require 'test/helper'

class Nanoc3::DirectedGraphTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_direct_predecessors
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)

    assert_equal [],    graph.direct_predecessors_of(1)
    assert_equal [ 1 ], graph.direct_predecessors_of(2)
    assert_equal [ 2 ], graph.direct_predecessors_of(3)
  end

  def test_predecessors
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)

    assert_equal [],       graph.predecessors_of(1).sort
    assert_equal [ 1 ],    graph.predecessors_of(2).sort
    assert_equal [ 1, 2 ], graph.predecessors_of(3).sort
  end

  def test_direct_successors
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)

    assert_equal [ 2 ], graph.direct_successors_of(1)
    assert_equal [ 3 ], graph.direct_successors_of(2)
    assert_equal [],    graph.direct_successors_of(3)
  end

  def test_successors
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)

    assert_equal [ 2, 3 ], graph.successors_of(1).sort
    assert_equal [ 3 ],    graph.successors_of(2).sort
    assert_equal [],       graph.successors_of(3).sort
  end

  def test_edges
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)

    assert_equal [ [ 0, 1 ], [ 1, 2 ] ], graph.edges.sort
  end

  def test_add_edge
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    
    assert_equal [], graph.successors_of(1)
    assert_equal [], graph.predecessors_of(2)

    graph.add_edge(1, 2)

    assert_equal [ 2 ], graph.successors_of(1)
    assert_equal [ 1 ], graph.predecessors_of(2)
  end

  def test_remove_edge
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])
    graph.add_edge(1,2)

    assert_equal [ 2 ], graph.successors_of(1)
    assert_equal [ 1 ], graph.predecessors_of(2)

    graph.remove_edge(1, 2)

    assert_equal [], graph.successors_of(1)
    assert_equal [], graph.predecessors_of(2)
  end

  def test_should_return_empty_array_for_nonexistant_vertices
    graph = Nanoc3::DirectedGraph.new([ 1, 2, 3 ])

    assert_equal [], graph.direct_predecessors_of(4)
    assert_equal [], graph.predecessors_of(4)
    assert_equal [], graph.direct_successors_of(4)
    assert_equal [], graph.successors_of(4)
  end

end
