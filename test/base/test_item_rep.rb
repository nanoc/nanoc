# encoding: utf-8

require 'test/helper'

class Nanoc3::ItemRepTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_created_modified_compiled
    # TODO implement
  end

  def test_not_outdated
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_nil rep.outdatedness_reason
  end

  def test_outdated_if_item_checksum_nil
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = nil
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :not_enough_data, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_force_outdated
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'
    rep.force_outdated = true

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :forced, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_compiled_file_doesnt_exist
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Check
    assert !File.file?('moo.html')
    assert_equal :not_written, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_item_checksum_is_different
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:bbb'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :source_modified, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_layouts_outdated
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:bbb')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :layouts_outdated, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_code_snippets_outdated
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:bbb')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :code_outdated, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_config_outdated
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:bbb')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:aaa')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :config_outdated, (rep.outdatedness_reason || {})[:type]
  end

  def test_outdated_if_rules_outdated
    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:new_checksum).returns('l:aaa')
    layouts[0].stubs(:old_checksum).returns('l:aaa')

    # Mock code snippets
    code_snippets = [ mock ]
    code_snippets[0].stubs(:new_checksum).returns('cs:aaa')
    code_snippets[0].stubs(:old_checksum).returns('cs:aaa')

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code_snippets).returns(code_snippets)
    site.stubs(:new_config_checksum).returns('co:aaa')
    site.stubs(:old_config_checksum).returns('co:aaa')
    site.stubs(:new_rules_checksum).returns('r:bbb')
    site.stubs(:old_rules_checksum).returns('r:aaa')

    # Mock item
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :checksum => 'i:aaa'
    )
    item.old_checksum = 'i:aaa'
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.raw_path = 'moo.html'

    # Write output file
    File.open(rep.raw_path, 'w') { |io| io.write("o hai how r u") }

    # Check
    assert_equal :rules_outdated, (rep.outdatedness_reason || {})[:type]
  end

  def test_compiled_content_with_only_last_available
    # Create rep
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc3::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content
  end

  def test_compiled_content_with_pre_and_last_available
    # Create rep
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc3::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :pre => 'pre content', :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'pre content', rep.compiled_content
  end

  def test_compiled_content_with_custom_snapshot
    # Create rep
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc3::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :pre => 'pre content', :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content(:snapshot => :last)
  end

  def test_compiled_content_with_invalid_snapshot
    # Create rep
    item = Nanoc3::Item.new(
      'blah blah blah', {}, '/',
      :binary => false, :mtime => Time.now-500
    )
    rep = Nanoc3::ItemRep.new(item, nil)
    rep.instance_eval { @content = { :pre => 'pre content', :last => 'last content' } }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal nil, rep.compiled_content(:snapshot => :klsjflkasdfl)
  end

  def test_compiled_content_with_uncompiled_content
    # Create rep
    item = Nanoc3::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )
    rep = Nanoc3::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)

    # Check
    assert_raises(Nanoc3::Errors::UnmetDependency) do
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
    item = Nanoc3::Item.new(
      %[<%= '<%= "blah" %' + '>' %>], {}, '/',
      :binary => false
    )
    item.site = site

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Filter once
    item_rep.filter(:erb)
    assert_equal(%[<%= "blah" %>], item_rep.instance_eval { @content[:last] })

    # Filter twice
    item_rep.filter(:erb)
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

  def test_layout
    # Mock layout
    layout = mock
    layout.stubs(:identifier).returns('/somelayout/')
    layout.stubs(:raw_content).returns(%[<%= "blah" %>])

    # Mock compiler
    stack = mock
    stack.expects(:push).with(layout)
    stack.expects(:pop)
    compiler = mock
    compiler.stubs(:stack).returns(stack)
    compiler.expects(:filter_for_layout).with(layout).returns([ :erb, {} ])

    # Mock site
    site = mock
    site.stubs(:items).returns([])
    site.stubs(:config).returns([])
    site.stubs(:layouts).returns([ layout ])
    site.stubs(:compiler).returns(compiler)

    # Mock item
    item = Nanoc3::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )
    item.site = site

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Layout
    item_rep.layout('/somelayout/')
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

  def test_layout_multiple
    # Mock layout 1
    layouts = [ mock, mock ]
    layouts[0].stubs(:identifier).returns('/one/')
    layouts[0].stubs(:raw_content).returns('{one}<%= yield %>{/one}')
    layouts[1].stubs(:identifier).returns('/two/')
    layouts[1].stubs(:raw_content).returns('{two}<%= yield %>{/two}')

    # Mock compiler
    stack = mock
    stack.stubs(:push)
    stack.stubs(:pop)
    compiler = mock
    compiler.stubs(:stack).returns(stack)
    compiler.stubs(:filter_for_layout).returns([ :erb, {} ])

    # Mock site
    site = mock
    site.stubs(:items).returns([])
    site.stubs(:config).returns([])
    site.stubs(:layouts).returns(layouts)
    site.stubs(:compiler).returns(compiler)

    # Mock item
    item = Nanoc3::Item.new('blah', {}, '/', :binary => false)
    item.site = site

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Layout
    item_rep.layout('/one/')
    item_rep.layout('/two/')
    assert_equal('blah',                       item_rep.instance_eval { @content[:pre]  })
    assert_equal('{two}{one}blah{/one}{/two}', item_rep.instance_eval { @content[:post] })
    assert_equal('{two}{one}blah{/one}{/two}', item_rep.instance_eval { @content[:last] })
  end

  def test_snapshot
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = Nanoc3::Item.new(
      %[<%= '<%= "blah" %' + '>' %>], {}, '/foobar/',
      :binary => false
    )
    item.site = site

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.raw_content
      @content[:last] = @content[:raw]
    end

    # Filter while taking snapshots
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

  def test_write
    # Mock item
    item = Nanoc3::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
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
    item = Nanoc3::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    rep = Nanoc3::ItemRep.new(item, '/foo/')
    def rep.assigns ; {} ; end

    # Create fake filter
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc3::Filter) do
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
    item = Nanoc3::Item.new(
      "blah blah", {}, '/',
      :binary => false
    )

    # Create rep
    rep = Nanoc3::ItemRep.new(item, '/foo/')
    def rep.assigns ; {} ; end

    # Create fake filter
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc3::Filter) do
        type :binary
        def run(content, params={})
          File.open(output_filename, 'w') { |io| io.write(content) }
        end
      end
    end

    # Run
    assert_raises ::Nanoc3::Errors::CannotUseBinaryFilter do
      rep.filter(:foo)
    end
  end

  def test_filter_get_compiled_content_from_binary_item
    # Mock item
    item = Nanoc3::Item.new(
      "blah blah", {}, '/',
      :binary => true
    )

    # Create rep
    rep = Nanoc3::ItemRep.new(item, '/foo/')
    def rep.compiled? ; true ; end

    # Check
    assert_nil rep.compiled_content
  end

  def test_using_textual_filters_on_binary_reps_raises
    item = create_binary_item
    site = mock_and_stub(:items => [item],
      :layouts => [],
      :config  => []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, '/foo/')
    create_textual_filter

    assert rep.binary?
    assert_raises(Nanoc3::Errors::CannotUseTextualFilter) { rep.filter(:text_filter) }
  end

  def test_writing_binary_reps_uses_content_in_last_filename
    require 'tempfile'

    in_filename  = 'nanoc-in'
    out_filename = 'nanoc-out'
    file_content = 'Some content for this test'
    File.open(in_filename, 'w') { |io| io.write(file_content) }

    item = create_binary_item
    rep = create_rep_for(item, /foo/)
    rep.instance_eval { @filenames[:last] = in_filename }
    rep.raw_paths[:last] = out_filename

    rep.write

    assert(File.exist?(out_filename))
    assert_equal(file_content, File.read(out_filename))
  end

  def test_converted_binary_rep_can_be_layed_out
    layout = mock_and_stub(
      :identifier => '/somelayout/',
      :raw_content => %[<%= "blah" %> <%= yield %>]
    )

    # Mock compiler
    stack = mock_and_stub(:pop => layout)
    stack.stubs(:push).returns(stack)
    compiler = mock_and_stub(
      :stack => stack,
      :filter_for_layout => [ :erb, {} ]
    )

    # Mock site
    site = mock_and_stub(
      :items    => [],
      :config   => [],
      :layouts  => [ layout ],
      :compiler => compiler
    )

    item = create_binary_item
    item.site = site

    rep = create_rep_for(item, '/foo/')
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc3::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end

    rep.filter(:binary_to_text)
    rep.layout('/somelayout/')
    assert_equal('blah Some textual content', rep.instance_eval { @content[:last] })
  end

  def test_converted_binary_rep_can_be_filterd_with_textual_filters
    item = create_binary_item
    site = mock_and_stub(:items => [item],
      :layouts => [],
      :config  => []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, /foo/)
    create_textual_filter

    assert rep.binary?

    def rep.filter_named(name)
      Class.new(::Nanoc3::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:binary_to_text)
    assert !rep.binary?

    def rep.filter_named(name)
      Class.new(::Nanoc3::Filter) do
        type :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:text_filter)
    assert !rep.binary?
  end

  def test_converted_binary_rep_cannot_be_filterd_with_binary_filters
    item = create_binary_item
    site = mock_and_stub(
      :items   => [item],
      :layouts => [],
      :config  => []
    )
    item.stubs(:site).returns(site)
    rep = create_rep_for(item, '/foo/')
    create_binary_filter

    assert rep.binary?
    def rep.filter_named(name)
      @filter ||= Class.new(::Nanoc3::Filter) do
        type :binary => :text
        def run(content, params={})
          "Some textual content"
        end
      end
    end
    rep.filter(:binary_to_text)
    assert ! rep.binary?
    assert_raises(Nanoc3::Errors::CannotUseBinaryFilter) { rep.filter(:binary_filter) }
  end

private

  def create_binary_item
    Nanoc3::Item.new(
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
    Nanoc3::ItemRep.new(item, name)
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
    filter_klass = Class.new(Nanoc3::Filter)
    filter_klass.type(type)
    Nanoc3::Filter.register filter_klass, "#{type}_filter".to_sym
    filter_klass
  end

end
