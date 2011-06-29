# encoding: utf-8

class Nanoc::DependencyTrackerTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_initialize
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Verify no dependencies yet
    assert_empty tracker.objects_causing_outdatedness_of(items[0])
    assert_empty tracker.objects_causing_outdatedness_of(items[1])
  end

  def test_record_dependency
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
  end

  def test_record_dependency_no_self
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[0])
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
  end

  def test_record_dependency_no_doubles
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
  end

  def test_objects_causing_outdatedness_of
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
  end

  def test_objects_outdated_due_to
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    assert_contains_exactly [ items[0] ], tracker.objects_outdated_due_to(items[1])
  end

  def test_start_and_stop
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Start, do something and stop
    tracker.start
    Nanoc::NotificationCenter.post(:visit_started, items[0])
    Nanoc::NotificationCenter.post(:visit_started, items[1])
    Nanoc::NotificationCenter.post(:visit_ended,   items[1])
    Nanoc::NotificationCenter.post(:visit_ended,   items[0])
    tracker.stop

    # Verify dependencies
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
    assert_empty tracker.objects_causing_outdatedness_of(items[1])
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
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    tracker.record_dependency(items[1], items[3])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_contains_exactly [ items[1] ],           tracker.objects_causing_outdatedness_of(items[0])
    assert_contains_exactly [ items[2], items[3] ], tracker.objects_causing_outdatedness_of(items[1])
    assert_empty tracker.objects_causing_outdatedness_of(items[2])
    assert_empty tracker.objects_causing_outdatedness_of(items[3])
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
    tracker = Nanoc::DependencyTracker.new(old_items)

    # Record some dependencies
    tracker.record_dependency(old_items[0], old_items[1])
    tracker.record_dependency(old_items[1], old_items[2])
    tracker.record_dependency(old_items[1], old_items[3])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc::DependencyTracker.new(new_items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_contains_exactly [ items[1] ],       tracker.objects_causing_outdatedness_of(items[0])
    assert_contains_exactly [ items[2], nil ],  tracker.objects_causing_outdatedness_of(items[1])
    assert_empty tracker.objects_causing_outdatedness_of(items[2])
  end

  def test_store_graph_with_nils_in_dst
    # Mock items
    items = [ mock('0'), mock('1'), mock('2') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], nil)

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
    assert_contains_exactly [ nil ],      tracker.objects_causing_outdatedness_of(items[1])
  end

  def test_store_graph_with_nils_in_src
    # Mock items
    items = [ mock('0'), mock('1'), mock('2') ]
    items.each { |i| i.stubs(:type).returns(:item) }
    items[0].stubs(:reference).returns([ :item, '/aaa/' ])
    items[1].stubs(:reference).returns([ :item, '/bbb/' ])
    items[2].stubs(:reference).returns([ :item, '/ccc/' ])

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(nil,      items[2])

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])
    assert_empty tracker.objects_causing_outdatedness_of(items[1])
  end

  def test_forget_dependencies_for
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    assert_contains_exactly [ items[1] ], tracker.objects_causing_outdatedness_of(items[0])

    # Forget dependencies
    tracker.forget_dependencies_for(items[0])
    assert_empty tracker.objects_causing_outdatedness_of(items[0])
  end

end
