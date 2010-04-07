# encoding: utf-8

require 'test/helper'

class Nanoc3::CompilerTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_run_without_item
    # Mock items
    items = [ mock, mock ]
    items[0]
    items[1]

    # Mock reps
    items[0].stubs(:reps).returns([ mock ])
    items[1].stubs(:reps).returns([ mock, mock ])
    reps = items[0].reps + items[1].reps

    # Mock site
    site = mock
    site.stubs(:config).returns({ :output_dir => 'foo/bar/baz' })
    site.stubs(:items).returns(items)

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.expects(:compile_reps).with(reps)
    compiler.expects(:forget_dependencies_if_outdated).with(items)

    # Mock dependency tracker
    dependency_tracker = mock
    dependency_tracker.expects(:load_graph)
    dependency_tracker.expects(:store_graph)
    dependency_tracker.expects(:start)
    dependency_tracker.expects(:stop)
    dependency_tracker.expects(:propagate_outdatedness)
    compiler.stubs(:dependency_tracker).returns(dependency_tracker)

    # Run
    compiler.run

    # Make sure output dir is created
    assert(File.directory?('foo/bar/baz'))
  end

  def test_run_with_item
    # Mock items
    item = mock
    other_items = [ mock, mock ]

    # Mock reps
    item.stubs(:reps).returns([ mock, mock, mock ])
    other_items.each { |i| i.stubs(:reps).returns([ mock ]) }
    reps = item.reps + other_items[0].reps

    # Mock site
    site = mock
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.expects(:compile_reps).with(reps)
    compiler.expects(:forget_dependencies_if_outdated).with([ item, other_items[0] ])

    # Mock dependency tracker
    dependency_tracker = mock
    dependency_tracker.expects(:load_graph)
    dependency_tracker.expects(:store_graph)
    dependency_tracker.expects(:start)
    dependency_tracker.expects(:stop)
    dependency_tracker.expects(:propagate_outdatedness)
    dependency_tracker.expects(:successors_of).with(item).returns([ other_items[0] ])
    compiler.stubs(:dependency_tracker).returns(dependency_tracker)

    # Run
    compiler.run(item)

    # Make sure output dir is created
    assert(File.directory?('foo/bar/baz'))
  end

  def test_run_with_force
    # Mock items
    items = [ mock, mock ]
    items[0]
    items[1]

    # Mock reps
    items[0].stubs(:reps).returns([ mock ])
    items[1].stubs(:reps).returns([ mock, mock ])
    reps = items[0].reps + items[1].reps
    reps.each { |r| r.expects(:force_outdated=).with(true) }

    # Mock site
    site = mock
    site.stubs(:config).returns({ :output_dir => 'foo/bar/baz' })
    site.stubs(:items).returns(items)

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.expects(:compile_reps).with(reps)
    compiler.expects(:forget_dependencies_if_outdated).with(items)

    # Mock dependency tracker
    dependency_tracker = mock
    dependency_tracker.expects(:load_graph)
    dependency_tracker.expects(:store_graph)
    dependency_tracker.expects(:start)
    dependency_tracker.expects(:stop)
    compiler.stubs(:dependency_tracker).returns(dependency_tracker)

    # Run
    compiler.run(nil, :force => true)

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

  def test_filter_for_layout_with_existant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[/.*/] = [ :erb, { :foo => 'bar' } ]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal([ :erb, { :foo => 'bar' } ], compiler.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_existant_layout_and_unknown_filter
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[/.*/] = [ :some_unknown_filter, { :foo => 'bar' } ]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal([ :some_unknown_filter, { :foo => 'bar' } ], compiler.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_nonexistant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[%r{^/foo/$}] = [ :erb, { :foo => 'bar' } ]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/bar/')

    # Check
    assert_equal(nil, compiler.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_many_layouts
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc3::Compiler.new(site)
    compiler.layout_filter_mapping[%r{^/a/b/c/.*/$}] = [ :erb, { :char => 'd' } ]
    compiler.layout_filter_mapping[%r{^/a/.*/$}]     = [ :erb, { :char => 'b' } ]
    compiler.layout_filter_mapping[%r{^/a/b/.*/$}]   = [ :erb, { :char => 'c' } ] # never used!
    compiler.layout_filter_mapping[%r{^/.*/$}]       = [ :erb, { :char => 'a' } ]

    # Mock layout
    layouts = [ mock, mock, mock, mock ]
    layouts[0].stubs(:identifier).returns('/a/b/c/d/')
    layouts[1].stubs(:identifier).returns('/a/b/c/')
    layouts[2].stubs(:identifier).returns('/a/b/')
    layouts[3].stubs(:identifier).returns('/a/')

    # Get expectations
    expectations = {
      0 => 'd',
      1 => 'b', # never used! not c, because b takes priority
      2 => 'b',
      3 => 'a'
    }

    # Check
    expectations.each_pair do |num, char|
      filter_and_args = compiler.filter_for_layout(layouts[num])
      refute_nil(filter_and_args)
      assert_equal(char, filter_and_args[1][:char])
    end
  end

  def test_compile_rep
    # Mock rep
    item = mock
    rep = mock
    rep.expects(:compiled=).with(true)
    rep.expects(:raw_path).returns('output/foo.html')
    rep.expects(:write)
    rep.stubs(:item).returns(item)

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
    rep.expects(:outdated?).returns(true)

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.expects(:compile_rep).with(rep)

    # Compile
    compiler.send :compile_reps, [ rep ]
  end

  def test_compile_reps_with_two_independent_reps
    # Mock reps
    reps = [ mock, mock ]
    reps[0].expects(:outdated?).returns(true)
    reps[1].expects(:outdated?).returns(true)

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
    reps[0].expects(:outdated?).returns(true)
    reps[0].expects(:forget_progress)
    reps[1].expects(:item).returns(items[1])
    reps[1].expects(:name).returns('somerepname')
    reps[1].expects(:outdated?).returns(true)

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
    reps[0].expects(:outdated?).returns(true)
    reps[0].expects(:forget_progress)
    reps[1].expects(:item).returns(items[1])
    reps[1].expects(:name).returns('secondrep')
    reps[1].expects(:outdated?).returns(true)
    reps[1].expects(:forget_progress)

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

  def test_forget_dependencies_if_outdated
    # Mock items
    items = [ mock, mock, mock, mock ]
    items[0].stubs(:outdated?).returns(false)
    items[0].stubs(:outdated_due_to_dependencies?).returns(false)
    items[1].stubs(:outdated?).returns(true)
    items[1].stubs(:outdated_due_to_dependencies?).returns(false)
    items[2].stubs(:outdated?).returns(false)
    items[2].stubs(:outdated_due_to_dependencies?).returns(true)
    items[3].stubs(:outdated?).returns(true)
    items[3].stubs(:outdated_due_to_dependencies?).returns(true)

    # Mock dependency tracker
    dependency_tracker = mock
    dependency_tracker.expects(:forget_dependencies_for).times(3)

    # Create compiler
    compiler = Nanoc3::Compiler.new(nil)
    compiler.stubs(:dependency_tracker).returns(dependency_tracker)
    compiler.send :forget_dependencies_if_outdated, items
  end

end
