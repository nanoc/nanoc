# frozen_string_literal: true

require 'helper'

class Nanoc::Int::DirectedGraphTest < Nanoc::TestCase
  def test_add_edge
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])

    assert_equal [], graph.successors_of(1)
    assert_equal [], graph.predecessors_of(2)

    graph.add_edge(1, 2)

    assert_equal [2], graph.successors_of(1)
    assert_equal [1], graph.predecessors_of(2)
  end

  def test_add_edge_with_new_vertices
    graph = Nanoc::Int::DirectedGraph.new([1])
    graph.add_edge(1, 2)
    graph.add_edge(3, 2)

    assert graph.vertices.include?(2)
    assert graph.vertices.include?(3)
  end

  def test_delete_edge
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)

    assert_equal [2], graph.successors_of(1)
    assert_equal [1], graph.predecessors_of(2)

    graph.delete_edge(1, 2)

    assert_equal [], graph.successors_of(1)
    assert_equal [], graph.predecessors_of(2)
  end

  def test_delete_edges_from
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])

    graph.add_edge(1, 2)
    graph.add_edge(2, 1)
    graph.add_edge(2, 3)
    graph.add_edge(3, 2)
    graph.add_edge(1, 3)
    graph.add_edge(3, 1)

    assert_equal [2, 3], graph.direct_predecessors_of(1).sort
    assert_equal [2, 3], graph.direct_successors_of(1).sort
    assert_equal [1, 3], graph.direct_predecessors_of(2).sort
    assert_equal [1, 3], graph.direct_successors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort
    assert_equal [1, 2], graph.direct_successors_of(3).sort
    assert_equal Set.new([]), graph.roots

    graph.delete_edges_from(1)

    assert_equal [2, 3], graph.direct_predecessors_of(1).sort
    assert_equal [], graph.direct_successors_of(1).sort
    assert_equal [3], graph.direct_predecessors_of(2).sort
    assert_equal [1, 3], graph.direct_successors_of(2).sort
    assert_equal [2], graph.direct_predecessors_of(3).sort
    assert_equal [1, 2], graph.direct_successors_of(3).sort
    assert_equal Set.new([]), graph.roots

    graph.delete_edges_from(2)

    assert_equal [3], graph.direct_predecessors_of(1).sort
    assert_equal [], graph.direct_successors_of(1).sort
    assert_equal [3], graph.direct_predecessors_of(2).sort
    assert_equal [], graph.direct_successors_of(2).sort
    assert_equal [], graph.direct_predecessors_of(3).sort
    assert_equal [1, 2], graph.direct_successors_of(3).sort
    assert_equal Set.new([3]), graph.roots
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
    assert_equal [2, 3], graph.direct_successors_of(1).sort
    assert_equal [1, 3], graph.direct_predecessors_of(2).sort
    assert_equal [1, 3], graph.direct_successors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort
    assert_equal [1, 2], graph.direct_successors_of(3).sort
    assert_equal Set.new([]), graph.roots

    graph.delete_edges_to(1)

    assert_equal [], graph.direct_predecessors_of(1).sort
    assert_equal [2, 3], graph.direct_successors_of(1).sort
    assert_equal [1, 3], graph.direct_predecessors_of(2).sort
    assert_equal [3], graph.direct_successors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort
    assert_equal [2], graph.direct_successors_of(3).sort
    assert_equal Set.new([1]), graph.roots

    graph.delete_edges_to(2)

    assert_equal [], graph.direct_predecessors_of(1).sort
    assert_equal [3], graph.direct_successors_of(1).sort
    assert_equal [], graph.direct_predecessors_of(2).sort
    assert_equal [3], graph.direct_successors_of(2).sort
    assert_equal [1, 2], graph.direct_predecessors_of(3).sort
    assert_equal [], graph.direct_successors_of(3).sort
    assert_equal Set.new([1, 2]), graph.roots
  end

  def test_should_return_empty_array_for_nonexistant_vertices
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])

    assert_equal [], graph.direct_predecessors_of(4)
    assert_equal [], graph.predecessors_of(4)
    assert_equal [], graph.direct_successors_of(4)
    assert_equal [], graph.successors_of(4)
  end

  def test_roots_after_init
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])

    assert_equal Set.new([1, 2, 3]), graph.roots
  end

  def test_roots_after_adding_edge
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)
    assert_equal Set.new([1, 3]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 3)
    assert_equal Set.new([1, 2]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(2, 1)
    assert_equal Set.new([2, 3]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)
    assert_equal Set.new([1]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)
    graph.add_edge(3, 1)
    assert_equal Set.new([]), graph.roots
  end

  def test_roots_after_removing_edge
    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)
    graph.delete_edge(1, 2)
    assert_equal Set.new([1, 2, 3]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 3)
    assert_equal Set.new([1, 2]), graph.roots
    graph.delete_edge(1, 2) # no such edge
    assert_equal Set.new([1, 2]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(2, 1)
    graph.delete_edge(2, 1)
    assert_equal Set.new([1, 2, 3]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)
    graph.delete_edge(1, 2)
    assert_equal Set.new([1, 2]), graph.roots
    graph.delete_edge(2, 3)
    assert_equal Set.new([1, 2, 3]), graph.roots

    graph = Nanoc::Int::DirectedGraph.new([1, 2, 3])
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)
    graph.add_edge(3, 1)
    graph.delete_edge(1, 2)
    assert_equal Set.new([2]), graph.roots
    graph.delete_edge(2, 3)
    assert_equal Set.new([2, 3]), graph.roots
    graph.delete_edge(3, 1)
    assert_equal Set.new([1, 2, 3]), graph.roots
  end

  def test_example
    YARD.parse(LIB_DIR + '/nanoc/base/entities/directed_graph.rb')
    assert_examples_correct 'Nanoc::Int::DirectedGraph'
  end
end
