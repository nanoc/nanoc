# frozen_string_literal: true

require 'helper'

class Nanoc::Int::DependencyTrackerTest < Nanoc::TestCase
  def test_initialize
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Verify no dependencies yet
    assert_empty store.objects_causing_outdatedness_of(items.to_a[0])
    assert_empty store.objects_causing_outdatedness_of(items.to_a[1])
  end

  def test_record_dependency
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])

    # Verify dependencies
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
  end

  def test_record_dependency_no_self
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[0])
    store.record_dependency(items.to_a[0], items.to_a[1])

    # Verify dependencies
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
  end

  def test_record_dependency_no_doubles
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[0], items.to_a[1])

    # Verify dependencies
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
  end

  def test_objects_causing_outdatedness_of
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[1], items.to_a[2])

    # Verify dependencies
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
  end

  def test_store_graph_and_load_graph_simple
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
      Nanoc::Int::Item.new('d', {}, '/d.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[1], items.to_a[2])
    store.record_dependency(items.to_a[1], items.to_a[3])

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
    assert_contains_exactly [items.to_a[2], items.to_a[3]], store.objects_causing_outdatedness_of(items.to_a[1])
    assert_empty store.objects_causing_outdatedness_of(items.to_a[2])
    assert_empty store.objects_causing_outdatedness_of(items.to_a[3])
  end

  def test_store_graph_and_load_graph_with_removed_items
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
      Nanoc::Int::Item.new('d', {}, '/d.md'),
    ])

    # Create new and old lists
    old_items = Nanoc::Int::IdentifiableCollection.new(config, [items.to_a[0], items.to_a[1], items.to_a[2], items.to_a[3]])
    new_items = Nanoc::Int::IdentifiableCollection.new(config, [items.to_a[0], items.to_a[1], items.to_a[2]])

    # Create
    store = Nanoc::Int::DependencyStore.new(old_items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[1], items.to_a[2])
    store.record_dependency(items.to_a[1], items.to_a[3])

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(new_items, layouts, config)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items.to_a[1]],       store.objects_causing_outdatedness_of(items.to_a[0])
    assert_contains_exactly [items.to_a[2], nil],  store.objects_causing_outdatedness_of(items.to_a[1])
    assert_empty store.objects_causing_outdatedness_of(items.to_a[2])
  end

  def test_store_graph_with_nils_in_dst
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[1], nil)

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
    assert_contains_exactly [nil], store.objects_causing_outdatedness_of(items.to_a[1])
  end

  def test_store_graph_with_nils_in_src
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(nil, items.to_a[2])

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])
    assert_empty store.objects_causing_outdatedness_of(items.to_a[1])
  end

  def test_forget_dependencies_for
    # Mock objects
    config = Nanoc::Int::Configuration.new.with_defaults
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    items = Nanoc::Int::IdentifiableCollection.new(config, [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ])

    # Create
    store = Nanoc::Int::DependencyStore.new(items, layouts, config)

    # Record some dependencies
    store.record_dependency(items.to_a[0], items.to_a[1])
    store.record_dependency(items.to_a[1], items.to_a[2])
    assert_contains_exactly [items.to_a[1]], store.objects_causing_outdatedness_of(items.to_a[0])

    # Forget dependencies
    store.forget_dependencies_for(items.to_a[0])
    assert_empty store.objects_causing_outdatedness_of(items.to_a[0])
  end
end
