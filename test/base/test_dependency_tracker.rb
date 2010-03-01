# encoding: utf-8

require 'test/helper'

class Nanoc3::DependencyTrackerTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_initialize
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Verify no dependencies yet
    assert_equal [], tracker.direct_predecessors_of(items[0])
    assert_equal [], tracker.direct_predecessors_of(items[1])
  end

  def test_record_dependency
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
  end

  def test_record_dependency_no_self
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[0])
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
  end

  def test_record_dependency_no_doubles
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
  end

  def test_direct_predecessors_of
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
  end

  def test_predecessors_of
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    all_dependencies = tracker.predecessors_of(items[0])
    assert_equal 2, all_dependencies.size
    assert all_dependencies.include?(items[1])
    assert all_dependencies.include?(items[2])
  end

  def test_direct_successors_of
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    assert_equal [ items[0] ], tracker.direct_successors_of(items[1])
  end

  def test_successors_of
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    all_dependencies = tracker.successors_of(items[2])
    assert_equal 2, all_dependencies.size
    assert all_dependencies.include?(items[0])
    assert all_dependencies.include?(items[1])
  end

  def test_start_and_stop
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Start, do something and stop
    tracker.start
    Nanoc3::NotificationCenter.post(:visit_started, items[0])
    Nanoc3::NotificationCenter.post(:visit_started, items[1])
    Nanoc3::NotificationCenter.post(:visit_ended,   items[1])
    Nanoc3::NotificationCenter.post(:visit_ended,   items[0])
    tracker.stop

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
    assert_equal [],           tracker.direct_predecessors_of(items[1])
  end

  def test_store_graph_and_load_graph_simple
    # Mock items
    items = [ mock, mock, mock, mock ]
    items[0].stubs(:identifier).returns('/aaa/')
    items[1].stubs(:identifier).returns('/bbb/')
    items[2].stubs(:identifier).returns('/ccc/')
    items[3].stubs(:identifier).returns('/ddd/')

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    tracker.record_dependency(items[1], items[3])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_equal [ items[1] ],           tracker.direct_predecessors_of(items[0])
    assert_equal [ items[2], items[3] ], tracker.direct_predecessors_of(items[1])
    assert_equal [],                     tracker.direct_predecessors_of(items[2])
    assert_equal [],                     tracker.direct_predecessors_of(items[3])
  end

  def test_store_graph_with_custom_filename
    # Mock items
    items = [ mock, mock, mock, mock ]
    items[0].stubs(:identifier).returns('/aaa/')
    items[1].stubs(:identifier).returns('/bbb/')
    items[2].stubs(:identifier).returns('/ccc/')
    items[3].stubs(:identifier).returns('/ddd/')

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)
    tracker.filename = 'tmp/bob/iguana/bits'

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    tracker.record_dependency(items[1], items[3])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)
    assert File.file?('tmp/bob/iguana/bits')
  end

  def test_store_graph_and_load_graph_with_removed_items
    # Mock items
    items = [ mock, mock, mock, mock ]
    items[0].stubs(:identifier).returns('/aaa/')
    items[1].stubs(:identifier).returns('/bbb/')
    items[2].stubs(:identifier).returns('/ccc/')
    items[3].stubs(:identifier).returns('/ddd/')

    # Create new and old lists
    old_items = [ items[0], items[1], items[2], items[3] ]
    new_items = [ items[0], items[1], items[2]           ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(old_items)

    # Record some dependencies
    tracker.record_dependency(old_items[0], old_items[1])
    tracker.record_dependency(old_items[1], old_items[2])
    tracker.record_dependency(old_items[1], old_items[3])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc3::DependencyTracker.new(new_items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
    assert_equal [ items[2] ], tracker.direct_predecessors_of(items[1])
    assert_equal [],           tracker.direct_predecessors_of(items[2])
  end

  def test_store_graph_with_nils_in_dst
    # Mock items
    items = [ mock, mock, mock ]
    items[0].stubs(:identifier).returns('/aaa/')
    items[1].stubs(:identifier).returns('/bbb/')
    items[2].stubs(:identifier).returns('/ccc/')

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], nil)

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
    assert_equal [ ],          tracker.direct_predecessors_of(items[1])
  end

  def test_store_graph_with_nils_in_src
    # Mock items
    items = [ mock, mock, mock ]
    items[0].stubs(:identifier).returns('/aaa/')
    items[1].stubs(:identifier).returns('/bbb/')
    items[2].stubs(:identifier).returns('/ccc/')

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(nil,      items[2])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])
    assert_equal [ ],          tracker.direct_predecessors_of(items[1])
  end

  def test_load_graph_without_file
    # Mock items
    item_0 = Object.new
    def item_0.outdated?                        ; false                             ; end
    def item_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    item_1 = Object.new
    def item_1.outdated?                        ; true                              ; end
    def item_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    items = [ item_0, item_1 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item_0, item_1 ])

    # Load
    tracker.load_graph
    graph = tracker.instance_eval { @graph }

    # Check
    refute tracker.nil?
    refute graph.nil?
    assert_equal [ nil ] + items, graph.vertices
    assert_equal [], tracker.direct_predecessors_of(items[0])
    assert_equal [], tracker.direct_predecessors_of(items[1])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert item_0.outdated_due_to_dependencies?
    assert item_1.outdated_due_to_dependencies?
  end

  def test_item_with_identifier
    # Mock items
    items = [ mock, mock, mock, mock ]
    items[0].stubs(:identifier).returns('/aaa/')
    items[1].stubs(:identifier).returns('/bbb/')
    items[2].stubs(:identifier).returns('/ccc/')
    items[3].stubs(:identifier).returns('/ddd/')

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Test
    assert_equal items[0], tracker.send(:item_with_identifier, '/aaa/')
    assert_equal items[1], tracker.send(:item_with_identifier, '/bbb/')
    assert_equal items[2], tracker.send(:item_with_identifier, '/ccc/')
    assert_equal items[3], tracker.send(:item_with_identifier, '/ddd/')
    assert_equal nil,      tracker.send(:item_with_identifier, '/123/')
  end

  def test_propagate_outdatedness_simple
    # Mock items
    item_0 = Object.new
    def item_0.outdated?                        ; false                             ; end
    def item_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    item_1 = Object.new
    def item_1.outdated?                        ; true                              ; end
    def item_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    items = [ item_0, item_1 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)
    tracker.instance_eval { @previous_items = items }

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !items[0].outdated?
    assert items[0].outdated_due_to_dependencies?
    assert items[1].outdated?
    assert !items[1].outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_chained
    # Mock items
    item_0 = Object.new
    def item_0.outdated?                        ; false                             ; end
    def item_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    item_1 = Object.new
    def item_1.outdated?                        ; false                             ; end
    def item_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    item_2 = Object.new
    def item_2.outdated?                        ; true                              ; end
    def item_2.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_2.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    items = [ item_0, item_1, item_2 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)
    tracker.instance_eval { @previous_items = items }

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !items[0].outdated?
    assert items[0].outdated_due_to_dependencies?
    assert !items[1].outdated?
    assert items[1].outdated_due_to_dependencies?
    assert items[2].outdated?
    assert !items[2].outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_with_removed_items_forward
    # A removed item (nil) that appears as a value marks all dependent items as outdated.

    # Mock items
    item = Object.new
    def item.outdated?                        ; false                             ; end
    def item.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item ])
    tracker.instance_eval { @previous_items = [ item ] }

    # Record some dependencies
    tracker.record_dependency(item, nil)

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !item.outdated?
    assert item.outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_with_removed_items_backward
    # A removed item (nil) that appears as a key can be ignored safely.

    # Mock items
    item = Object.new
    def item.outdated?                        ; true                              ; end
    def item.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item ])
    tracker.instance_eval { @previous_items = [ item ] }

    # Record some dependencies
    tracker.record_dependency(nil, item)

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert item.outdated?
    assert !item.outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_with_added_items
    # An added item (with no entry in the dependency graph) depends on all other items.

    # Mock items
    item_0 = Object.new
    def item_0.outdated?                        ; false                             ; end
    def item_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    item_1 = Object.new
    def item_1.outdated?                        ; false                             ; end
    def item_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def item_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item_0, item_1 ])
    tracker.instance_eval { @previous_items = [ item_0 ] }

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !item_0.outdated_due_to_dependencies?
    assert item_1.outdated_due_to_dependencies?
  end

  def test_forget_dependencies_for
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    assert_equal [ items[1] ], tracker.direct_predecessors_of(items[0])

    # Forget dependencies
    tracker.forget_dependencies_for(items[0])
    assert_equal [], tracker.direct_predecessors_of(items[0])
  end

end
