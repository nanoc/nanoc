# encoding: utf-8

class Nanoc::ItemRepTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_created_modified_compiled
    # TODO implement
  end

  def test_compiled_content_with_only_last_available
    # Create rep
    item = Nanoc::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content
  end

  def test_compiled_content_with_pre_and_last_available
    # Create rep
    item = Nanoc::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :pre => 'pre content', :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'pre content', rep.compiled_content
  end

  def test_compiled_content_with_custom_snapshot
    # Create rep
    item = Nanoc::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :pre => 'pre content', :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content(:snapshot => :last)
  end

  def test_compiled_content_with_invalid_snapshot
    # Create rep
    item = Nanoc::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :pre => 'pre content', :last => 'last content' } }

    # Check
    assert_raises Nanoc::Errors::NoSuchSnapshot do
      rep.compiled_content(:snapshot => :klsjflkasdfl)
    end
  end

  def test_compiled_content_with_uncompiled_content
    # Create rep
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )
    rep = Nanoc::ItemRep.new(item, nil)
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
    item = Nanoc::Item.new(
      %[<%= '<%= "blah" %' + '>' %>], {}, '/',
      :binary => false
    )

    # Create item rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Filter once
    item_rep.assigns = {}
    item_rep.filter(:erb)
    assert_equal(%[<%= "blah" %>], item_rep.instance_eval { @content[:last] })

    # Filter twice
    item_rep.assigns = {}
    item_rep.filter(:erb)
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

  def test_layout
    # Mock layout
    layout = Nanoc::Layout.new(%[<%= "blah" %>], {}, '/somelayout/')

    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create item rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Layout
    item_rep.assigns = {}
    item_rep.layout(layout, :erb, {})
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
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
      :binary => false
    )

    # Create item rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Filter while taking snapshots
    item_rep.assigns = {}
    item_rep.snapshot(:foo)
    item_rep.filter(:erb)
    item_rep.snapshot(:bar)
    item_rep.filter(:erb)
    item_rep.snapshot(:qux)

    # Check snapshots
    assert_equal(%[<%= '<%= "blah" %' + '>' %>], item_rep.instance_eval { @content[:foo] })
    assert_equal(%[<%= "blah" %>],               item_rep.instance_eval { @content[:bar] })
    assert_equal(%[blah],                        item_rep.instance_eval { @content[:qux] })
  end

  def test_snapshot_should_be_written
    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    item_rep.instance_eval { @content[:last] = 'Lorem ipsum, etc.' }
    item_rep.raw_paths = { :moo => 'foo-moo.txt' }

    # Test non-final
    refute File.file?(item_rep.raw_path(:snapshot => :moo))
    item_rep.snapshot(:moo, :final => false)
    refute File.file?(item_rep.raw_path(:snapshot => :moo))

    # Test final 1
    item_rep.snapshot(:moo, :final => true)
    assert File.file?(item_rep.raw_path(:snapshot => :moo))
    assert_equal 'Lorem ipsum, etc.', File.read(item_rep.raw_path(:snapshot => :moo))
    FileUtils.rm_f(item_rep.raw_path(:snapshot => :moo))

    # Test final 2
    item_rep.snapshot(:moo)
    assert File.file?(item_rep.raw_path(:snapshot => :moo))
    assert_equal 'Lorem ipsum, etc.', File.read(item_rep.raw_path(:snapshot => :moo))
  end

  def test_write_should_not_touch_identical_textual_files
    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    def item_rep.generate_diff ; end
    item_rep.instance_eval { @content[:last] = 'Lorem ipsum, etc.' }
    item_rep.raw_path = 'foo/bar/baz/quux.txt'

    # Write once
    item_rep.write
    a_long_time_ago = Time.now-1_000_000
    File.utime(a_long_time_ago, a_long_time_ago, item_rep.raw_path)

    # Write again
    assert_equal a_long_time_ago.to_s, File.mtime(item_rep.raw_path).to_s
    item_rep.write
    assert_equal a_long_time_ago.to_s, File.mtime(item_rep.raw_path).to_s
  end

  def test_write_should_not_touch_identical_binary_files
    # Create temporary source file
    File.open('blahblah', 'w') { |io| io.write("Blah blah…") }
    full_file_path = File.expand_path('blahblah')

    # Mock item
    item = Nanoc::Item.new(
      full_file_path, {}, '/',
      :binary => true
    )

    # Create rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    item_rep.raw_path = 'foo/bar/baz/quux'

    # Write once
    item_rep.write
    a_long_time_ago = Time.now-1_000_000
    File.utime(a_long_time_ago, a_long_time_ago, item_rep.raw_path)

    # Write again
    assert_equal a_long_time_ago.to_s, File.mtime(item_rep.raw_path).to_s
    item_rep.write
    assert_equal a_long_time_ago.to_s, File.mtime(item_rep.raw_path).to_s
  end

  def test_write
    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    item_rep = Nanoc::ItemRep.new(item, :foo)
    item_rep.instance_eval { @content[:last] = 'Lorem ipsum, etc.' }
    item_rep.raw_path = 'foo/bar/baz/quux.txt'

    # Write
    item_rep.write

    # Check
    assert(File.file?('foo/bar/baz/quux.txt'))
    assert_equal('Lorem ipsum, etc.', File.read('foo/bar/baz/quux.txt'))
  end

  def test_filter_text_to_binary
    # Mock item
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    rep = Nanoc::ItemRep.new(item, :foo)
    def rep.assigns ; {} ; end

    # Create fake filter
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :text => :binary
        def run(content, params={})
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
    item = Nanoc::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    rep = Nanoc::ItemRep.new(item, :foo)
    def rep.assigns ; {} ; end

    # Create fake filter
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :binary
        def run(content, params={})
          File.open(output_filename, 'w') { |io| io.write(content) }
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

    assert rep.binary?
    assert_raises(Nanoc::Errors::CannotUseTextualFilter) { rep.filter(:text_filter) }
  end

  def test_writing_binary_reps_uses_content_in_last_filename
    require 'tempfile'

    in_filename  = 'nanoc-in'
    out_filename = 'nanoc-out'
    file_content = 'Some content for this test'
    File.open(in_filename, 'w') { |io| io.write(file_content) }

    item = create_binary_item
    rep = create_rep_for(item, :foo)
    rep.temporary_filenames[:last] = in_filename
    rep.raw_paths[:last]           = out_filename

    rep.write

    assert(File.exist?(out_filename))
    assert_equal(file_content, File.read(out_filename))
  end

  def test_converted_binary_rep_can_be_layed_out
    # Mock layout
    layout = Nanoc::Layout.new(%[<%= "blah" %> <%= yield %>], {}, '/somelayout/')

    # Create item and item rep
    item = create_binary_item
    rep = create_rep_for(item, :foo)
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
    assert_equal('blah meh', rep.instance_eval { @content[:last] })
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

    assert rep.binary?

    def rep.filter_named(name)
      Class.new(::Nanoc::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:binary_to_text)
    assert !rep.binary?

    def rep.filter_named(name)
      Class.new(::Nanoc::Filter) do
        type :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:text_filter)
    assert !rep.binary?
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

    assert rep.binary?
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:binary_to_text)
    refute rep.binary?
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
    rep = Nanoc::ItemRep.new(item, :default)
    rep.instance_eval { @filter_class = filter_class }
    def rep.filter_named(name) ; @filter_class ; end

    raised = false
    begin
      rep.filter(:whatever)
    rescue => e
      raised = true
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised
  end

  def test_filter_should_freeze_content
    filter_class = Class.new(::Nanoc::Filter) do
      def run(content, params={})
        content.gsub!('foo', 'moo')
        content
      end
    end

    item = Nanoc::Item.new("foo bar", {}, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default)
    rep.instance_eval { @filter_class = filter_class }
    def rep.filter_named(name) ; @filter_class ; end

    raised = false
    begin
      rep.filter(:erb)
      rep.filter(:whatever)
    rescue => e
      raised = true
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised
  end

  def test_raw_path_should_generate_dependency
    items = [
      Nanoc3::Item.new("foo", {}, '/foo/'),
      Nanoc3::Item.new("bar", {}, '/bar/')
    ]
    item_reps = [
      Nanoc3::ItemRep.new(items[0], :default),
      Nanoc3::ItemRep.new(items[1], :default)
    ]

    dt = Nanoc3::DependencyTracker.new(items)
    dt.start
    Nanoc3::NotificationCenter.post(:visit_started, items[0])
    item_reps[1].raw_path
    Nanoc3::NotificationCenter.post(:visit_ended,   items[0])
    dt.stop

    assert_equal [ items[1] ], dt.objects_causing_outdatedness_of(items[0])
  end

  def test_path_should_generate_dependency
    items = [
      Nanoc3::Item.new("foo", {}, '/foo/'),
      Nanoc3::Item.new("bar", {}, '/bar/')
    ]
    item_reps = [
      Nanoc3::ItemRep.new(items[0], :default),
      Nanoc3::ItemRep.new(items[1], :default)
    ]

    dt = Nanoc3::DependencyTracker.new(items)
    dt.start
    Nanoc3::NotificationCenter.post(:visit_started, items[0])
    item_reps[1].path
    Nanoc3::NotificationCenter.post(:visit_ended,   items[0])
    dt.stop

    assert_equal [ items[1] ], dt.objects_causing_outdatedness_of(items[0])
  end

private

  def create_binary_item
    Nanoc::Item.new(
      "/a/file/name.dat", {}, '/',
      :binary => true
    )
  end

  def mock_and_stub(params)
    m = mock
    params.each do |method, return_value|
      m.stubs(method.to_sym).returns( return_value )
    end
    m
  end

  def create_rep_for(item, name)
    Nanoc::ItemRep.new(item, name)
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
