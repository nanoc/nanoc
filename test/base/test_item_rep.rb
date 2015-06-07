class Nanoc::Int::ItemRepTest < Nanoc::TestCase
  def test_created_modified_compiled
    # TODO: implement
  end

  def test_compiled_content_with_only_last_available
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.content_snapshots = {
      last: Nanoc::Int::TextualContent.new('last content'),
    }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content
  end

  def test_compiled_content_with_pre_and_last_available
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.content_snapshots = {
      pre: Nanoc::Int::TextualContent.new('pre content'),
      last: Nanoc::Int::TextualContent.new('last content'),
    }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'pre content', rep.compiled_content
  end

  def test_compiled_content_with_custom_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.content_snapshots = {
      pre: Nanoc::Int::TextualContent.new('pre content'),
      last: Nanoc::Int::TextualContent.new('last content'),
    }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content(snapshot: :last)
  end

  def test_compiled_content_with_invalid_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.content_snapshots = {
      pre: Nanoc::Int::TextualContent.new('pre content'),
      last: Nanoc::Int::TextualContent.new('last content'),
    }

    # Check
    assert_raises Nanoc::Int::Errors::NoSuchSnapshot do
      rep.compiled_content(snapshot: :klsjflkasdfl)
    end
  end

  def test_compiled_content_with_uncompiled_content
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)

    # Check
    assert_raises(Nanoc::Int::Errors::UnmetDependency) do
      rep.compiled_content
    end
  end

  def test_compiled_content_with_moving_pre_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)
    rep.content_snapshots = {
      pre: Nanoc::Int::TextualContent.new('pre!'),
      last: Nanoc::Int::TextualContent.new('last!'),
    }

    # Check
    assert_raises(Nanoc::Int::Errors::UnmetDependency) do
      rep.compiled_content(snapshot: :pre)
    end
  end

  def test_compiled_content_with_non_moving_pre_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)
    rep.snapshots = [[:pre, true]]
    rep.content_snapshots = {
      pre: Nanoc::Int::TextualContent.new('pre!'),
      post: Nanoc::Int::TextualContent.new('post!'),
      last: Nanoc::Int::TextualContent.new('last!'),
    }

    # Check
    assert_equal 'pre!', rep.compiled_content(snapshot: :pre)
  end

  def test_compiled_content_with_final_pre_snapshot_in_layout
    # Mock layout
    layout = Nanoc::Int::Layout.new(
      %(BEFORE <%= @item_rep.compiled_content(snapshot: :pre) %> AFTER),
      {},
      '/somelayout/')

    # Create item and item rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = create_rep_for(item, :foo)
    rep.assigns = { item_rep: rep }

    # Run and check
    rep.layout(layout, :erb, {})
    assert_equal('BEFORE blah blah AFTER', rep.content_snapshots[:last].string)
  end

  def test_filter
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = Nanoc::Int::Item.new(
      %(<%= '<%= "blah" %' + '>' %>), {}, '/',
    )

    # Create item rep
    item_rep = Nanoc::Int::ItemRep.new(item, :foo)
    item_rep.content_snapshots = {
      raw:  item.content,
      last: item.content,
    }

    # Filter once
    item_rep.assigns = {}
    item_rep.filter(:erb)
    assert_equal(%(<%= "blah" %>), item_rep.content_snapshots[:last].string)

    # Filter twice
    item_rep.assigns = {}
    item_rep.filter(:erb)
    assert_equal(%(blah), item_rep.content_snapshots[:last].string)
  end

  def test_layout
    # Mock layout
    layout = Nanoc::Int::Layout.new(%(<%= "blah" %>), {}, '/somelayout/')

    # Mock item
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )

    # Create item rep
    item_rep = Nanoc::Int::ItemRep.new(item, :foo)
    item_rep.content_snapshots = {
      raw:  item.content,
      last: item.content,
    }

    # Layout
    item_rep.assigns = {}
    item_rep.layout(layout, :erb, {})
    assert_equal(%(blah), item_rep.content_snapshots[:last].string)
  end

  def test_snapshot
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = Nanoc::Int::Item.new(
      %(<%= '<%= "blah" %' + '>' %>), {}, '/foobar/',
    )

    # Create item rep
    item_rep = Nanoc::Int::ItemRep.new(item, :foo)
    item_rep.content_snapshots = {
      raw:  item.content,
      last: item.content,
    }

    # Filter while taking snapshots
    item_rep.assigns = {}
    item_rep.snapshot(:foo)
    item_rep.filter(:erb)
    item_rep.snapshot(:bar)
    item_rep.filter(:erb)
    item_rep.snapshot(:qux)

    # Check snapshots
    assert_equal(%(<%= '<%= "blah" %' + '>' %>), item_rep.content_snapshots[:foo].string)
    assert_equal(%(<%= "blah" %>),               item_rep.content_snapshots[:bar].string)
    assert_equal(%(blah),                        item_rep.content_snapshots[:qux].string)
  end

  def test_snapshot_should_be_written
    # Mock item
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )

    # Create rep
    item_rep = Nanoc::Int::ItemRep.new(item, :foo)
    item_rep.content_snapshots = { last: Nanoc::Int::TextualContent.new('Lorem ipsum, etc.') }
    item_rep.raw_paths = { moo: 'foo-moo.txt' }

    # Test non-final
    refute File.file?(item_rep.raw_path(snapshot: :moo))
    item_rep.snapshot(:moo, final: false)
    refute File.file?(item_rep.raw_path(snapshot: :moo))

    # Test final 1
    item_rep.snapshot(:moo, final: true)
    assert File.file?(item_rep.raw_path(snapshot: :moo))
    assert_equal 'Lorem ipsum, etc.', File.read(item_rep.raw_path(snapshot: :moo))
    FileUtils.rm_f(item_rep.raw_path(snapshot: :moo))

    # Test final 2
    item_rep.snapshot(:moo)
    assert File.file?(item_rep.raw_path(snapshot: :moo))
    assert_equal 'Lorem ipsum, etc.', File.read(item_rep.raw_path(snapshot: :moo))
  end

  def test_filter_text_to_binary
    # Mock item
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )

    # Create rep
    rep = Nanoc::Int::ItemRep.new(item, :foo)
    def rep.assigns
      {}
    end

    # Create fake filter
    def rep.filter_named(_name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type text: :binary
        def run(content, _params = {})
          File.open(output_filename, 'w') { |io| io.write(content) }
        end
      end
    end

    # Run
    rep.filter(:foo)

    # Check
    assert rep.binary?
  end

  def test_filter_with_textual_rep_and_binary_filter
    # Mock item
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )

    # Create rep
    rep = Nanoc::Int::ItemRep.new(item, :foo)
    def rep.assigns
      {}
    end

    # Create fake filter
    def rep.filter_named(_name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :binary
        def run(content, _params = {})
          File.open(output_filename, 'w') { |io| io.write(content) }
        end
      end
    end

    # Run
    assert_raises ::Nanoc::Int::Errors::CannotUseBinaryFilter do
      rep.filter(:foo)
    end
  end

  def test_using_textual_filters_on_binary_reps_raises
    item = create_binary_item
    site = mock_and_stub(items: [item],
      layouts: [],
      config: [])
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, :foo)
    create_textual_filter

    assert rep.binary?
    assert_raises(Nanoc::Int::Errors::CannotUseTextualFilter) { rep.filter(:text_filter) }
  end

  def test_converted_binary_rep_can_be_layed_out
    # Mock layout
    layout = Nanoc::Int::Layout.new(%(<%= "blah" %> <%= yield %>), {}, '/somelayout/')

    # Create item and item rep
    item = create_binary_item
    rep = create_rep_for(item, :foo)
    rep.assigns = { content: 'meh' }

    # Create filter
    Class.new(::Nanoc::Filter) do
      type binary: :text
      identifier :binary_to_text
      def run(content, _params = {})
        content + ' textified'
      end
    end

    # Run and check
    rep.filter(:binary_to_text)
    rep.layout(layout, :erb, {})
    assert_equal('blah meh', rep.content_snapshots[:last].string)
  end

  def test_converted_binary_rep_can_be_filtered_with_textual_filters
    item = create_binary_item
    site = mock_and_stub(items: [item],
      layouts: [],
      config: [])
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, :foo)
    rep.assigns = {}
    create_textual_filter

    assert rep.binary?

    def rep.filter_named(_name)
      Class.new(::Nanoc::Filter) do
        type binary: :text
        def run(_content, _params = {})
          'Some textual content'
        end
      end
    end
    rep.filter(:binary_to_text)
    assert !rep.binary?

    def rep.filter_named(_name)
      Class.new(::Nanoc::Filter) do
        type :text
        def run(_content, _params = {})
          'Some textual content'
        end
      end
    end
    rep.filter(:text_filter)
    assert !rep.binary?
  end

  def test_converted_binary_rep_cannot_be_filtered_with_binary_filters
    item = create_binary_item
    site = mock_and_stub(
      items: [item],
      layouts: [],
      config: []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, :foo)
    rep.assigns = {}
    create_binary_filter

    assert rep.binary?
    def rep.filter_named(_name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type binary: :text
        def run(_content, _params = {})
          'Some textual content'
        end
      end
    end
    rep.filter(:binary_to_text)
    refute rep.binary?
    assert_raises(Nanoc::Int::Errors::CannotUseBinaryFilter) { rep.filter(:binary_filter) }
  end

  def test_new_content_should_be_frozen
    filter_class = Class.new(::Nanoc::Filter) do
      def run(content, _params = {})
        content.gsub!('foo', 'moo')
        content
      end
    end

    item = Nanoc::Int::Item.new('foo bar', {}, '/foo/')
    item.freeze
    assert item.content.frozen?
    assert item.content.string.frozen?
    rep = Nanoc::Int::ItemRep.new(item, :default)
    rep.instance_eval { @filter_class = filter_class }
    def rep.filter_named(_name)
      @filter_class
    end

    assert_raises_frozen_error do
      rep.filter(:whatever)
    end
  end

  def test_filter_should_freeze_content
    filter_class = Class.new(::Nanoc::Filter) do
      def run(content, _params = {})
        content.gsub!('foo', 'moo')
        content
      end
    end

    item = Nanoc::Int::Item.new('foo bar', {}, '/foo/')
    item.freeze
    assert item.content.frozen?
    assert item.content.string.frozen?
    rep = Nanoc::Int::ItemRep.new(item, :default)
    rep.instance_eval { @filter_class = filter_class }
    def rep.filter_named(_name)
      @filter_class
    end

    assert_raises_frozen_error do
      rep.filter(:erb)
      rep.filter(:whatever)
    end
  end

  def test_raw_path_should_generate_dependency
    items = [
      Nanoc::Int::Item.new('foo', {}, '/foo/'),
      Nanoc::Int::Item.new('bar', {}, '/bar/')
    ]
    item_reps = [
      Nanoc::Int::ItemRep.new(items[0], :default),
      Nanoc::Int::ItemRep.new(items[1], :default)
    ]

    dt = Nanoc::Int::DependencyTracker.new(items)
    dt.start
    Nanoc::Int::NotificationCenter.post(:visit_started, items[0])
    item_reps[1].raw_path
    Nanoc::Int::NotificationCenter.post(:visit_ended,   items[0])
    dt.stop

    assert_equal [items[1]], dt.objects_causing_outdatedness_of(items[0])
  end

  def test_path_should_generate_dependency
    items = [
      Nanoc::Int::Item.new('foo', {}, '/foo/'),
      Nanoc::Int::Item.new('bar', {}, '/bar/')
    ]
    item_reps = [
      Nanoc::Int::ItemRep.new(items[0], :default),
      Nanoc::Int::ItemRep.new(items[1], :default)
    ]

    dt = Nanoc::Int::DependencyTracker.new(items)
    dt.start
    Nanoc::Int::NotificationCenter.post(:visit_started, items[0])
    item_reps[1].path
    Nanoc::Int::NotificationCenter.post(:visit_ended,   items[0])
    dt.stop

    assert_equal [items[1]], dt.objects_causing_outdatedness_of(items[0])
  end

  def test_access_compiled_content_of_binary_item
    content = Nanoc::Int::BinaryContent.new(File.expand_path('content/somefile.dat'))
    item = Nanoc::Int::Item.new(content, {}, '/somefile/')
    item_rep = Nanoc::Int::ItemRep.new(item, :foo)
    assert_raises(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem) do
      item_rep.compiled_content
    end
  end

  private

  def create_binary_item
    Nanoc::Int::Item.new(
      Nanoc::Int::BinaryContent.new('/a/file/name.dat'), {}, '/')
  end

  def mock_and_stub(params)
    m = mock
    params.each do |method, return_value|
      m.stubs(method.to_sym).returns(return_value)
    end
    m
  end

  def create_rep_for(item, name)
    Nanoc::Int::ItemRep.new(item, name)
  end

  def create_textual_filter
    f = create_filter(:text)
    f.class_eval do
      def run(_content, _params = {})
        ''
      end
    end
    f
  end

  def create_binary_filter
    f = create_filter(:binary)
    f.class_eval do
      def run(content, _params = {})
        File.open(output_filename, 'w') { |io| io.write(content) }
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
