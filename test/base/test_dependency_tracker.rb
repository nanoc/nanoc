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
    items = [ mock('0'), mock('1'), mock('2'), mock('3') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])
    items[3].stubs(:reference).returns([ :item, '/ddd/' ])

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
    items = [ mock('0'), mock('1'), mock('2'), mock('3') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])
    items[3].stubs(:reference).returns([ :item, '/ddd/' ])

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
    items = [ mock('0'), mock('1'), mock('2'), mock('3') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])
    items[3].stubs(:reference).returns([ :item, '/ddd/' ])

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
    items = [ mock('0'), mock('1'), mock('2') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])

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
    items = [ mock('0'), mock('1'), mock('2') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])

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

  def test_propagate_outdatedness_simple
    # Mock objects
    object_0 = Object.new
    def object_0.outdated?                        ; false                             ; end
    def object_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    object_1 = Object.new
    def object_1.outdated?                        ; true                              ; end
    def object_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    objects = [ object_0, object_1 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(objects)
    tracker.instance_eval { @previous_objects = objects }

    # Record some dependencies
    tracker.record_dependency(objects[0], objects[1])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !objects[0].outdated?
    assert objects[0].outdated_due_to_dependencies?
    assert objects[1].outdated?
    assert !objects[1].outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_chained
    # Mock objects
    object_0 = Object.new
    def object_0.outdated?                        ; false                             ; end
    def object_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    object_1 = Object.new
    def object_1.outdated?                        ; false                             ; end
    def object_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    object_2 = Object.new
    def object_2.outdated?                        ; true                              ; end
    def object_2.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_2.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    objects = [ object_0, object_1, object_2 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(objects)
    tracker.instance_eval { @previous_objects = objects }

    # Record some dependencies
    tracker.record_dependency(objects[0], objects[1])
    tracker.record_dependency(objects[1], objects[2])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !objects[0].outdated?
    assert objects[0].outdated_due_to_dependencies?
    assert !objects[1].outdated?
    assert objects[1].outdated_due_to_dependencies?
    assert objects[2].outdated?
    assert !objects[2].outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_with_removed_objects_forward
    # A removed object (nil) that appears as a value marks all dependent objects as outdated.

    # Mock objects
    object = Object.new
    def object.outdated?                        ; false                             ; end
    def object.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ object ])
    tracker.instance_eval { @previous_objects = [ object ] }

    # Record some dependencies
    tracker.record_dependency(object, nil)

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !object.outdated?
    assert object.outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_with_removed_objects_backward
    # A removed object (nil) that appears as a key can be ignored safely.

    # Mock objects
    object = Object.new
    def object.outdated?                        ; true                              ; end
    def object.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ object ])
    tracker.instance_eval { @previous_objects = [ object ] }

    # Record some dependencies
    tracker.record_dependency(nil, object)

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert object.outdated?
    assert !object.outdated_due_to_dependencies?
  end

  def test_propagate_outdatedness_with_added_objects
    # An added object (with no entry in the dependency graph) depends on all other objects.

    # Mock objects
    object_0 = Object.new
    def object_0.outdated?                        ; false                             ; end
    def object_0.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_0.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end
    object_1 = Object.new
    def object_1.outdated?                        ; false                             ; end
    def object_1.outdated_due_to_dependencies?    ; @outdated_due_to_dependencies     ; end
    def object_1.outdated_due_to_dependencies=(b) ; @outdated_due_to_dependencies = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ object_0, object_1 ])
    tracker.instance_eval { @previous_objects = [ object_0 ] }

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    assert !object_0.outdated_due_to_dependencies?
    assert object_1.outdated_due_to_dependencies?
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
