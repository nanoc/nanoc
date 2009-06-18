# encoding: utf-8

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

    # Create site
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

  def test_compilation_rule_for
    # Mock rules
    rules = [ mock, mock, mock ]
    rules[0].expects(:applicable_to?).returns(false)
    rules[1].expects(:applicable_to?).returns(true)
    rules[1].expects(:rep_name).returns('wrong')
    rules[2].expects(:applicable_to?).returns(true)
    rules[2].expects(:rep_name).returns('right')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.instance_eval { @item_compilation_rules = rules }

    # Mock rep
    rep = mock
    rep.stubs(:name).returns('right')
    item = mock
    rep.stubs(:item).returns(item)

    # Test
    assert_equal rules[2], compiler.compilation_rule_for(rep)
  end

  def test_routing_rule_for
    # Mock rules
    rules = [ mock, mock, mock ]
    rules[0].expects(:applicable_to?).returns(false)
    rules[1].expects(:applicable_to?).returns(true)
    rules[1].expects(:rep_name).returns('wrong')
    rules[2].expects(:applicable_to?).returns(true)
    rules[2].expects(:rep_name).returns('right')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.instance_eval { @item_routing_rules = rules }

    # Mock rep
    rep = mock
    rep.stubs(:name).returns('right')
    item = mock
    rep.stubs(:item).returns(item)

    # Test
    assert_equal rules[2], compiler.routing_rule_for(rep)
  end

  def test_filter_name_for_layout_with_existant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[/.*/] = :erb

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal(:erb, compiler.filter_name_for_layout(layout))
  end

  def test_filter_name_for_layout_with_existant_layout_and_unknown_filter
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[/.*/] = :some_unknown_filter

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal(:some_unknown_filter, compiler.filter_name_for_layout(layout))
  end

  def test_filter_name_for_layout_with_nonexistant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[%r{^/foo/$}] = :erb

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/bar/')

    # Check
    assert_equal(nil, compiler.filter_name_for_layout(layout))
  end

  def test_compile_rep_with_not_outdated_rep
    # Mock rep
    rep = mock
    rep.expects(:outdated?).returns(false)

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)

    # Compile
    compiler.send :compile_rep, rep
  end

  def test_compile_rep_with_outdated_rep
    # Mock rep
    rep = mock
    rep.expects(:outdated?).returns(true)
    rep.expects(:compiled=).with(true)

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compilation_rule = mock
    compilation_rule.expects(:apply_to).with(rep)
    compiler.expects(:compilation_rule_for).returns(compilation_rule)

    # Compile
    compiler.send :compile_rep, rep
  end

  def test_compile_reps_with_no_reps
    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.expects(:compile_rep).never

    # Compile
    compiler.send :compile_reps, []
  end

  def test_compile_reps_with_one_rep
    # Mock rep
    rep = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.expects(:compile_rep).with(rep)

    # Compile
    compiler.send :compile_reps, [ rep ]
  end

  def test_compile_reps_with_two_independent_reps
    # Mock reps
    reps = [ mock, mock ]

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.expects(:compile_rep).times(2)

    # Compile
    compiler.send :compile_reps, reps

    # Check size of reps array
    assert_equal 2, reps.size
  end

  def test_compile_reps_with_two_dependent_reps
    # Mock items
    items = [ mock, mock ]
    items[1].expects(:identifier).returns('/foo/bar/')

    # Mock reps
    reps  = [ mock, mock ]
    reps[1].expects(:item).returns(items[1])
    reps[1].expects(:name).returns('somerepname')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.instance_eval { @_reps = reps }
    def compiler.compile_rep(rep)
      @_invocation_id ||= 0
      @_called_reps   ||= []

      case @_invocation_id
      when 0
        @_invocation_id = 1
        @_called_reps[0] = rep
        raise Nanoc3::Errors::UnmetDependency.new(@_reps[1])
      when 1
        @_invocation_id = 2
        @_called_reps[1] = rep
      when 2
        @_invocation_id = 3
        @_called_reps[2] = rep
      end
    end

    # Compile
    compiler.send :compile_reps, reps

    # Check
    assert_equal reps[0], compiler.instance_eval { @_called_reps[0] }
    assert_equal reps[1], compiler.instance_eval { @_called_reps[1] }
    assert_equal reps[0], compiler.instance_eval { @_called_reps[2] }
  end

  def test_compile_reps_with_two_mutually_dependent_reps
    # Mock items
    items = [ mock, mock ]
    items[0].expects(:identifier).returns('/first/')
    items[1].expects(:identifier).returns('/second/')

    # Mock reps
    reps  = [ mock, mock ]
    reps[0].expects(:item).returns(items[0])
    reps[0].expects(:name).returns('firstrep')
    reps[1].expects(:item).returns(items[1])
    reps[1].expects(:name).returns('secondrep')

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.instance_eval { @_reps = reps }
    def compiler.compile_rep(rep)
      if rep == @_reps[0]
        raise Nanoc3::Errors::UnmetDependency.new(@_reps[1])
      elsif rep == @_reps[1]
        raise Nanoc3::Errors::UnmetDependency.new(@_reps[0])
      else
        raise RuntimeError.new("this shouldn't have happened")
      end
    end

    # Compile
    assert_raises Nanoc3::Errors::RecursiveCompilation do
      compiler.send :compile_reps, reps
    end
  end

end
