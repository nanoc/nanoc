# encoding: utf-8

class Nanoc::ItemRepTest < Nanoc::TestCase

  def new_item
    item = Nanoc::Item.new(
      Nanoc::TextualContent.new('blah blah blah', File.absolute_path('content/somefile.md')),
      {},
      '/')
  end

  def new_snapshot_store
    Nanoc::SnapshotStore::SQLite3.new
  end

  def test_created_modified_compiled
    # TODO implement
  end

  def test_compiled_content_with_only_last_available
    # Create rep
    item = self.new_item
    snapshot_store = self.new_snapshot_store
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :last, 'last content')
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content
  end

  def test_compiled_content_with_pre_and_last_available
    # Create rep
    item = self.new_item
    snapshot_store = self.new_snapshot_store
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :pre,  'pre content')
    snapshot_store.set('/', :foo, :last, 'last content')
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content
  end

  def test_compiled_content_with_custom_snapshot
    # Create rep
    item = self.new_item
    snapshot_store = self.new_snapshot_store
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :pre,  'pre content')
    snapshot_store.set('/', :foo, :last, 'last content')
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content(:snapshot => :last)
  end

  def test_compiled_content_with_invalid_snapshot
    # Create rep
    item = self.new_item
    snapshot_store = self.new_snapshot_store
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :pre,  'pre content')
    snapshot_store.set('/', :foo, :last, 'last content')

    # Check
    assert_raises Nanoc::Errors::NoSuchSnapshot do
      rep.compiled_content(:snapshot => :klsjflkasdfl)
    end
  end

  def test_compiled_content_with_uncompiled_content
    # Create rep
    item = self.new_item
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => self.new_snapshot_store)
    rep.expects(:compiled?).returns(false)

    # Check
    assert_raises(Nanoc::Errors::UnmetDependency) do
      rep.compiled_content
    end
  end

  def test_filter
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = Nanoc::Item.new(%[<%= '<%= "blah" %' + '>' %>], {}, '/')

    # Create item rep
    snapshot_store = self.new_snapshot_store
    item_rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :raw,  item.content.string)
    snapshot_store.set('/', :foo, :last, item.content.string)

    # Filter once
    item_rep.assigns = {}
    item_rep.filter(:erb)
    assert_equal(%[<%= "blah" %>], snapshot_store.query('/', :foo, :last))

    # Filter twice
    item_rep.assigns = {}
    item_rep.filter(:erb)
    assert_equal(%[blah], snapshot_store.query('/', :foo, :last))
  end

  def test_layout
    # Mock layout
    layout = Nanoc::Layout.new(%[<%= "blah" %>], {}, '/somelayout/')

    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
    )

    # Create item rep
    snapshot_store = self.new_snapshot_store
    item_rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :raw,  item.content.string)
    snapshot_store.set('/', :foo, :last, item.content.string)

    # Layout
    item_rep.assigns = {}
    item_rep.layout(layout, :erb, {})
    assert_equal(%[blah], snapshot_store.query('/', :foo, :last))
  end

  def test_snapshot
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = Nanoc::Item.new(
      %[<%= '<%= "blah" %' + '>' %>], {}, '/foobar/',
    )

    # Create item rep
    snapshot_store = self.new_snapshot_store
    item_rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    snapshot_store.set('/', :foo, :raw,  item.content.string)
    snapshot_store.set('/', :foo, :last, item.content.string)

    # Filter while taking snapshots
    item_rep.assigns = {}
    item_rep.snapshot(:foo)
    item_rep.filter(:erb)
    item_rep.snapshot(:bar)
    item_rep.filter(:erb)
    item_rep.snapshot(:qux)

    # Check snapshots
    assert_equal(%[<%= '<%= "blah" %' + '>' %>], snapshot_store.query(item.identifier, :foo, :foo))
    assert_equal(%[<%= "blah" %>],               snapshot_store.query(item.identifier, :foo, :bar))
    assert_equal(%[blah],                        snapshot_store.query(item.identifier, :foo, :qux))
  end

  def test_filter_text_to_binary
    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
    )

    # Create rep
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => self.new_snapshot_store)
    def rep.assigns ; {} ; end

    # Create fake filter
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :text => :binary
        def run(content, params={})
          File.write(output_filename, content)
        end
      end
    end

    # Run
    rep.filter(:foo)

    # Check
    assert rep.snapshot_binary?(:last)
  end

  def test_filter_with_textual_rep_and_binary_filter
    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
    )

    # Create rep
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => self.new_snapshot_store)
    def rep.assigns ; {} ; end

    # Create fake filter
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :binary
        def run(content, params={})
          File.write(output_filename, content)
        end
      end
    end

    # Run
    assert_raises ::Nanoc::Errors::CannotUseBinaryFilter do
      rep.filter(:foo)
    end
  end

  def test_using_textual_filters_on_binary_reps_raises
    item = create_binary_item
    site = mock_and_stub(:items => [item],
      :layouts => [],
      :config  => []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, :foo)
    create_textual_filter

    assert rep.snapshot_binary?(:last)
    assert_raises(Nanoc::Errors::CannotUseTextualFilter) { rep.filter(:text_filter) }
  end

  def test_converted_binary_rep_can_be_layed_out
    # Mock layout
    layout = Nanoc::Layout.new(%[<%= "blah" %> <%= yield %>], {}, '/somelayout/')

    # Create item and item rep
    item = create_binary_item
    snapshot_store = self.new_snapshot_store
    rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => snapshot_store)
    rep.assigns = { :content => 'meh' }

    # Create filter
    Class.new(::Nanoc::Filter) do
      type       :binary => :text
      identifier :binary_to_text
      def run(content, params={})
        content + ' textified'
      end
    end

    # Run and check
    rep.filter(:binary_to_text)
    rep.layout(layout, :erb, {})
    assert_equal('blah meh', snapshot_store.query(item.identifier, :foo, :last))
  end

  def test_converted_binary_rep_can_be_filtered_with_textual_filters
    item = create_binary_item
    site = mock_and_stub(:items => [item],
      :layouts => [],
      :config  => []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, :foo)
    rep.assigns = {}
    create_textual_filter

    assert rep.snapshot_binary?(:last)

    def rep.filter_named(name)
      Class.new(::Nanoc::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:binary_to_text)
    assert !rep.snapshot_binary?(:last)

    def rep.filter_named(name)
      Class.new(::Nanoc::Filter) do
        type :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:text_filter)
    assert !rep.snapshot_binary?(:last)
  end

  def test_converted_binary_rep_cannot_be_filtered_with_binary_filters
    item = create_binary_item
    site = mock_and_stub(
      :items   => [item],
      :layouts => [],
      :config  => []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, :foo)
    rep.assigns = {}
    create_binary_filter

    assert rep.snapshot_binary?(:last)
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:binary_to_text)
    refute rep.snapshot_binary?(:last)
    assert_raises(Nanoc::Errors::CannotUseBinaryFilter) { rep.filter(:binary_filter) }
  end

  def test_new_content_should_be_frozen
    filter_class = Class.new(::Nanoc::Filter) do
      def run(content, params={})
        content.gsub!('foo', 'moo')
        content
      end
    end

    item = Nanoc::Item.new("foo bar", {}, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => self.new_snapshot_store)
    rep.instance_eval { @filter_class = filter_class }
    def rep.filter_named(name) ; @filter_class ; end

    assert_raises_frozen_error do
      rep.filter(:whatever)
    end
  end

  def test_filter_should_freeze_content
    filter_class = Class.new(::Nanoc::Filter) do
      def run(content, params={})
        content.gsub!('foo', 'moo')
        content
      end
    end

    item = Nanoc::Item.new("foo bar", {}, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => self.new_snapshot_store)
    rep.instance_eval { @filter_class = filter_class }
    def rep.filter_named(name) ; @filter_class ; end

    assert_raises_frozen_error do
      rep.filter(:erb)
      rep.filter(:whatever)
    end
  end

  def test_raw_path_should_generate_dependency
    items = [
      Nanoc::Item.new("foo", {}, '/foo/'),
      Nanoc::Item.new("bar", {}, '/bar/')
    ]
    item_reps = [
      Nanoc::ItemRep.new(items[0], :default, :snapshot_store => self.new_snapshot_store),
      Nanoc::ItemRep.new(items[1], :default, :snapshot_store => self.new_snapshot_store)
    ]

    dt = Nanoc::DependencyTracker.new(items)
    dt.start
    Nanoc::NotificationCenter.post(:visit_started, items[0])
    item_reps[1].raw_path
    Nanoc::NotificationCenter.post(:visit_ended,   items[0])
    dt.stop

    assert_equal [ items[1] ], dt.objects_causing_outdatedness_of(items[0])
  end

  def test_path_should_generate_dependency
    items = [
      Nanoc::Item.new("foo", {}, '/foo/'),
      Nanoc::Item.new("bar", {}, '/bar/')
    ]
    item_reps = [
      Nanoc::ItemRep.new(items[0], :default, :snapshot_store => self.new_snapshot_store),
      Nanoc::ItemRep.new(items[1], :default, :snapshot_store => self.new_snapshot_store)
    ]

    dt = Nanoc::DependencyTracker.new(items)
    dt.start
    Nanoc::NotificationCenter.post(:visit_started, items[0])
    item_reps[1].path
    Nanoc::NotificationCenter.post(:visit_ended,   items[0])
    dt.stop

    assert_equal [ items[1] ], dt.objects_causing_outdatedness_of(items[0])
  end

  def test_access_compiled_content_of_binary_item
    item = Nanoc::Item.new(Nanoc::BinaryContent.new(File.absolute_path('content/somefile.dat')), {}, '/somefile/')
    item_rep = Nanoc::ItemRep.new(item, :foo, :snapshot_store => self.new_snapshot_store)
    assert_raises(Nanoc::Errors::CannotGetCompiledContentOfBinaryItem) do
      item_rep.compiled_content
    end
  end

private

  def create_binary_item
    Nanoc::Item.new(Nanoc::BinaryContent.new('/a/file/name.dat'), {}, '/')
  end

  def mock_and_stub(params)
    m = mock
    params.each do |method, return_value|
      m.stubs(method.to_sym).returns( return_value )
    end
    m
  end

  def create_rep_for(item, name)
    Nanoc::ItemRep.new(item, name, :snapshot_store => self.new_snapshot_store)
  end

  def create_textual_filter
    f = create_filter(:text)
    f.class_eval do
      def run(content, params={})
        ""
      end
    end
    f
  end

  def create_binary_filter
    f = create_filter(:binary)
    f.class_eval do
      def run(content, params={})
        File.write(output_filename, content)
      end
    end
    f
  end

  def create_filter(type)
    filter_klass = Class.new(Nanoc::Filter)
    filter_klass.type(type)
    Nanoc::Filter.register filter_klass, "#{type}_filter".to_sym
    filter_klass
  end

end
