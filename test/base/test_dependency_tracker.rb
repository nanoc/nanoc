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
    assert_equal Set.new([ items[1] ]),           Set.new(tracker.direct_predecessors_of(items[0]))
    assert_equal Set.new([ items[2], items[3] ]), Set.new(tracker.direct_predecessors_of(items[1]))
    assert_equal Set.new([]),                     Set.new(tracker.direct_predecessors_of(items[2]))
    assert_equal Set.new([]),                     Set.new(tracker.direct_predecessors_of(items[3]))
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
    item_0 = Nanoc3::Item.new('content0', {}, '/blah0/')
    item_1 = Nanoc3::Item.new('content1', {}, '/blah1/')
    items = [ item_0, item_1 ]
    items.each do |item|
      item.reps << Nanoc3::ItemRep.new(item, :blah)
    end

    # Create site
    site = Nanoc3::Site.new({})

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.instance_eval do
       @outdatedness_reasons = {
         item_0.reps[0] => false,
         item_1.reps[0] => true
       }
    end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item_0, item_1 ])
    tracker.compiler = compiler

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
    assert tracker.outdated_due_to_dependencies?(item_0)
    assert tracker.outdated_due_to_dependencies?(item_1)
  end

  def test_propagate_outdatedness_simple
    # Mock objects
    object_0 = Nanoc3::Item.new('content0', {}, '/blah0/')
    object_1 = Nanoc3::Item.new('content1', {}, '/blah1/')
    objects = [ object_0, object_1 ]
    objects.each do |obj|
      obj.reps << Nanoc3::ItemRep.new(obj, :blah)
    end

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.instance_eval do
      @objs = [
        object_0,
        object_1
      ]
    end
    def compiler.outdated?(obj)
      case obj
      when @objs[0]
        false
      when @objs[1]
        true
      else
        raise RuntimeError, "I did not expect #{obj.inspect}"
      end
    end

    # Create
    tracker = Nanoc3::DependencyTracker.new(objects)
    tracker.instance_eval { @previous_objects = objects }
    tracker.compiler = compiler

    # Record some dependencies
    tracker.record_dependency(objects[0], objects[1])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    refute compiler.outdated?(objects[0])
    assert tracker.outdated_due_to_dependencies?(objects[0])
    assert compiler.outdated?(objects[1])
    refute tracker.outdated_due_to_dependencies?(objects[1])
  end

  def test_propagate_outdatedness_chained
    # Mock objects
    object_0 = Nanoc3::Item.new('content0', {}, '/blah0/')
    object_1 = Nanoc3::Item.new('content1', {}, '/blah1/')
    object_2 = Nanoc3::Item.new('content2', {}, '/blah2/')
    objects = [ object_0, object_1, object_2 ]
    objects.each do |obj|
      obj.reps << Nanoc3::ItemRep.new(obj, :blah)
    end

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.instance_eval do
      @objs = [
        object_0,
        object_1,
        object_2
      ]
    end
    def compiler.outdated?(obj)
      case obj
      when @objs[0], @objs[1]
        false
      when @objs[2]
        true
      else
        raise RuntimeError, "I did not expect #{obj.inspect}"
      end
    end

    # Create
    tracker = Nanoc3::DependencyTracker.new(objects)
    tracker.instance_eval { @previous_objects = objects }
    tracker.compiler = compiler

    # Record some dependencies
    tracker.record_dependency(objects[0], objects[1])
    tracker.record_dependency(objects[1], objects[2])

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    refute compiler.outdated?(objects[0])
    assert tracker.outdated_due_to_dependencies?(objects[0])
    refute compiler.outdated?(objects[1])
    assert tracker.outdated_due_to_dependencies?(objects[1])
    assert compiler.outdated?(objects[2])
    refute tracker.outdated_due_to_dependencies?(objects[2])
  end

  def test_propagate_outdatedness_with_removed_objects_forward
    # A removed object (nil) that appears as a value marks all dependent objects as outdated.

    # Mock objects
    object = Nanoc3::Item.new('content', {}, '/blah/')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.stubs(:outdated?).returns(false)

    # Create
    tracker = Nanoc3::DependencyTracker.new([ object ])
    tracker.instance_eval { @previous_objects = [ object ] }
    tracker.compiler = compiler

    # Record some dependencies
    tracker.record_dependency(object, nil)

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    refute compiler.outdated?(object)
    assert tracker.outdated_due_to_dependencies?(object)
  end

  def test_propagate_outdatedness_with_removed_objects_backward
    # A removed object (nil) that appears as a key can be ignored safely.

    # Mock objects
    object = Nanoc3::Item.new('content', {}, '/blah/')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.stubs(:outdated?).returns(false)

    # Create
    tracker = Nanoc3::DependencyTracker.new([ object ])
    tracker.instance_eval { @previous_objects = [ object ] }
    tracker.compiler = compiler

    # Record some dependencies
    tracker.record_dependency(nil, object)

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    refute compiler.outdated?(object)
    refute tracker.outdated_due_to_dependencies?(object)
  end

  def test_propagate_outdatedness_with_added_objects
    # An added object (with no entry in the dependency graph) depends on all other objects.

    # Mock objects
    object_0 = Nanoc3::Item.new('content', {}, '/blah/')
    object_1 = Nanoc3::Item.new('content', {}, '/blah/')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.stubs(:outdated?).returns(false)

    # Create
    tracker = Nanoc3::DependencyTracker.new([ object_0, object_1 ])
    tracker.instance_eval { @previous_objects = [ object_0 ] }
    tracker.compiler = compiler

    # Mark as outdated
    tracker.propagate_outdatedness

    # Check outdatedness
    refute tracker.outdated_due_to_dependencies?(object_0)
    assert tracker.outdated_due_to_dependencies?(object_1)
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
