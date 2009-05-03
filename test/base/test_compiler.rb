require 'test/helper'

class Nanoc3::CompilerTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_run_without_item
    # Create items
    items = [
      Nanoc3::Item.new('item one', {}, '/item1/'),
      Nanoc3::Item.new('item two', {}, '/item2/')
    ]

    # Mock reps
    items[0].stubs(:reps).returns([ mock ])
    items[1].stubs(:reps).returns([ mock, mock ])

    # Create site
    site = mock
    site.stubs(:config).returns({ :output_dir => 'foo/bar/baz' })
    site.stubs(:items).returns(items)

    # Set items' site
    items.each { |item| item.site = site }

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.expects(:compile_rep).times(3)

    # Run
    compiler.run

    # Make sure output dir is created
    assert(File.directory?('foo/bar/baz'))
  end

  def test_run_with_item_rep
    # Create item
    item = Nanoc3::Item.new('item one', {}, '/item1/')

    # Mock reps
    item.expects(:reps).returns([ mock, mock, mock ])

    # Create site and router
    site = mock
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })

    # Set item's site
    item.site = site

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.expects(:compile_rep).times(3)

    # Run
    compiler.run([ item ])

    # Make sure output dir is created
    assert(File.directory?('foo/bar/baz'))
  end

  def test_compile_rep
    # TODO implement
  end

  def test_compilation_rule_for
    # TODO implement
  end

  def test_filter_name_for_layout_with_existant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.add_layout_compilation_rule('*', :erb)

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, 'some_layout')

    # Check
    assert_equal(:erb, compiler.filter_name_for_layout(layout))
  end

  def test_filter_name_for_layout_with_existant_layout_and_unknown_filter
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.add_layout_compilation_rule('*', :some_unknown_filter)

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, 'some_layout')

    # Check
    assert_equal(:some_unknown_filter, compiler.filter_name_for_layout(layout))
  end

  def test_filter_name_for_layout_with_nonexistant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.add_layout_compilation_rule('foo', :erb)

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, 'bar')

    # Check
    assert_equal(nil, compiler.filter_name_for_layout(layout))
  end

  def test_add_item_compilation_rule
    # TODO implement
  end

  def test_add_layout_compilation_rule
    # TODO implement
  end

  def test_identifier_to_regex_without_wildcards
    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)

    # Check
    assert_equal(
      /^foo$/,
      compiler.instance_eval { identifier_to_regex('foo') }
    )
  end

  def test_identifier_to_regex_with_one_wildcard
    compiler = Nanoc3::Compiler.new(nil)

    actual   = compiler.instance_eval { identifier_to_regex('foo/*/bar') }
    expected = %r{^foo/(.*?)/bar$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_two_wildcards
    compiler = Nanoc3::Compiler.new(nil)

    actual   = compiler.instance_eval { identifier_to_regex('foo/*/bar/*/qux') }
    expected = %r{^foo/(.*?)/bar/(.*?)/qux$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

end
