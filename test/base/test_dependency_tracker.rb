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
    assert_equal [], tracker.direct_dependencies_for(items[0])
    assert_equal [], tracker.direct_dependencies_for(items[1])
  end

  def test_record_dependency
    # Mock items
    items = [ mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_dependencies_for(items[0])
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
    assert_equal [ items[1] ], tracker.direct_dependencies_for(items[0])
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
    assert_equal [ items[1] ], tracker.direct_dependencies_for(items[0])
  end

  def test_direct_dependencies_for
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    assert_equal [ items[1] ], tracker.direct_dependencies_for(items[0])
  end

  def test_all_dependencies_for
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])

    # Verify dependencies
    all_dependencies = tracker.all_dependencies_for(items[0])
    assert_equal 2, all_dependencies.size
    assert all_dependencies.include?(items[1])
    assert all_dependencies.include?(items[2])
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
    assert_equal [ items[1] ], tracker.direct_dependencies_for(items[0])
    assert_equal [],           tracker.direct_dependencies_for(items[1])
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
    tracker.send :complete_graph

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_equal [ items[1] ],           tracker.direct_dependencies_for(items[0])
    assert_equal [ items[2], items[3] ], tracker.direct_dependencies_for(items[1])
    assert_equal [],                     tracker.direct_dependencies_for(items[2])
    assert_equal [],                     tracker.direct_dependencies_for(items[3])
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
    tracker.send :complete_graph

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
    tracker.send :complete_graph

    # Store
    tracker.store_graph
    assert File.file?(tracker.filename)

    # Re-create
    tracker = Nanoc3::DependencyTracker.new(new_items)

    # Load
    tracker.load_graph

    # Check loaded graph
    assert_equal [ items[1] ],      tracker.direct_dependencies_for(items[0])
    assert_equal [ items[2], nil ], tracker.direct_dependencies_for(items[1])
    assert_equal [],                tracker.direct_dependencies_for(items[2])
    assert_equal [],                tracker.direct_dependencies_for(items[3])
  end

  def test_load_graph_without_file
    # Mock items
    item_0 = Object.new
    def item_0.outdated?                 ; false                      ; end
    def item_0.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_0.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    item_1 = Object.new
    def item_1.outdated?                 ; true                       ; end
    def item_1.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_1.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    items = [ item_0, item_1 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item_0, item_1 ])

    # Load
    tracker.load_graph
    assert_equal({}, tracker.instance_eval { @graph })

    # Mark as outdated
    tracker.mark_outdated_items

    # Check outdatedness
    assert item_0.dependencies_outdated?
    assert item_1.dependencies_outdated?
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

  def test_mark_outdated_items_simple
    # Mock items
    item_0 = Object.new
    def item_0.outdated?                 ; false                      ; end
    def item_0.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_0.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    def item_0.identifier                ; '/a/'                      ; end
    item_1 = Object.new
    def item_1.outdated?                 ; true                       ; end
    def item_1.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_1.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    def item_1.identifier                ; '/b/'                      ; end
    items = [ item_0, item_1 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.send :complete_graph

    # Mark as outdated
    tracker.mark_outdated_items

    # Check outdatedness
    assert !items[0].outdated?
    assert items[0].dependencies_outdated?
    assert items[1].outdated?
    assert !items[1].dependencies_outdated?
  end

  def test_mark_outdated_items_chained
    # Mock items
    item_0 = Object.new
    def item_0.outdated?                 ; false                      ; end
    def item_0.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_0.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    def item_0.identifier                ; '/a/'                      ; end
    item_1 = Object.new
    def item_1.outdated?                 ; false                      ; end
    def item_1.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_1.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    def item_1.identifier                ; '/b/'                      ; end
    item_2 = Object.new
    def item_2.outdated?                 ; true                       ; end
    def item_2.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item_2.dependencies_outdated=(b) ; @dependencies_outdated = b ; end
    def item_2.identifier                ; '/c/'                      ; end
    items = [ item_0, item_1, item_2 ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    tracker.send :complete_graph

    # Mark as outdated
    tracker.mark_outdated_items

    # Check outdatedness
    assert !items[0].outdated?
    assert items[0].dependencies_outdated?
    assert !items[1].outdated?
    assert items[1].dependencies_outdated?
    assert items[2].outdated?
    assert !items[2].dependencies_outdated?
  end

  def test_mark_outdated_items_with_removed_items_forward
    # A removed item (nil) that appears as a value marks all dependent items as outdated.

    # Mock items
    item = Object.new
    def item.outdated?                 ; false                      ; end
    def item.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item.dependencies_outdated=(b) ; @dependencies_outdated = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item ])

    # Record some dependencies
    tracker.record_dependency(item, nil)
    tracker.send :complete_graph

    # Mark as outdated
    tracker.mark_outdated_items

    # Check outdatedness
    assert !item.outdated?
    assert item.dependencies_outdated?
  end

  def test_mark_outdated_items_with_removed_items_backward
    # A removed item (nil) that appears as a key can be ignored safely.

    # Mock items
    item = Object.new
    def item.outdated?                 ; true                       ; end
    def item.identifier                ; '/bob/'                    ; end
    def item.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item.dependencies_outdated=(b) ; @dependencies_outdated = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item ])

    # Record some dependencies
    tracker.record_dependency(nil, item)
    tracker.send :complete_graph

    # Mark as outdated
    tracker.mark_outdated_items

    # Check outdatedness
    assert item.outdated?
    assert !item.dependencies_outdated?
  end

  def test_mark_outdated_items_with_added_items
    # An added item (with no entry in the dependency graph) depends on all other items.

    # Mock items
    item = Object.new
    def item.outdated?                 ; false                      ; end
    def item.dependencies_outdated?    ; @dependencies_outdated     ; end
    def item.dependencies_outdated=(b) ; @dependencies_outdated = b ; end

    # Create
    tracker = Nanoc3::DependencyTracker.new([ item ])

    # Mark as outdated
    tracker.mark_outdated_items

    # Check outdatedness
    assert item.dependencies_outdated?, 'items without entry in the dependency graph (i.e. added items) should be outdated'
  end

  def test_forget_dependencies_for
    # Mock items
    items = [ mock, mock, mock ]

    # Create
    tracker = Nanoc3::DependencyTracker.new(items)

    # Record some dependencies
    tracker.record_dependency(items[0], items[1])
    tracker.record_dependency(items[1], items[2])
    assert_equal [ items[1] ], tracker.direct_dependencies_for(items[0])

    # Forget dependencies
    tracker.forget_dependencies_for(items[0])
    assert_equal [], tracker.direct_dependencies_for(items[0])
  end

  def test_invert_graph
    # Create
    tracker = Nanoc3::DependencyTracker.new([])

    # Invert
    original = {
      :a => [ :b, :c ],
      :b => [ :x, :c ]
    }
    actual = tracker.send(:invert_graph, original)

    # Check
    expected = {
      :b => [ :a ],
      :c => [ :a, :b ],
      :x => [ :b ]
    }
    assert_equal expected, actual
  end

end
