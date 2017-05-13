# frozen_string_literal: true

require 'helper'

class Nanoc::RuleDSL::RulesCollectionTest < Nanoc::TestCase
  def test_compilation_rule_for
    # Mock rules
    rules = [mock, mock, mock]
    rules[0].expects(:applicable_to?).returns(false)
    rules[1].expects(:applicable_to?).returns(true)
    rules[1].expects(:rep_name).returns('wrong')
    rules[2].expects(:applicable_to?).returns(true)
    rules[2].expects(:rep_name).returns('right')

    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    rules_collection.instance_eval { @item_compilation_rules = rules }

    # Mock rep
    rep = mock
    rep.stubs(:name).returns('right')
    item = mock
    rep.stubs(:item).returns(item)

    # Test
    assert_equal rules[2], rules_collection.compilation_rule_for(rep)
  end

  def test_filter_for_layout_with_existant_layout
    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(/.*/)] = [:erb, { foo: 'bar' }]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal([:erb, { foo: 'bar' }], rules_collection.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_existant_layout_and_unknown_filter
    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(/.*/)] = [:some_unknown_filter, { foo: 'bar' }]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal([:some_unknown_filter, { foo: 'bar' }], rules_collection.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_nonexistant_layout
    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(%r{^/foo/$})] = [:erb, { foo: 'bar' }]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/bar/')

    # Check
    assert_equal(nil, rules_collection.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_many_layouts
    rules_collection = Nanoc::RuleDSL::RulesCollection.new
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(%r{^/a/b/c/.*/$})] = [:erb, { char: 'd' }]
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(%r{^/a/.*/$})]     = [:erb, { char: 'b' }]
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(%r{^/a/b/.*/$})]   = [:erb, { char: 'c' }] # never used!
    rules_collection.layout_filter_mapping[Nanoc::Int::Pattern.from(%r{^/.*/$})]       = [:erb, { char: 'a' }]

    # Mock layout
    layouts = [mock, mock, mock, mock]
    layouts[0].stubs(:identifier).returns('/a/b/c/d/')
    layouts[1].stubs(:identifier).returns('/a/b/c/')
    layouts[2].stubs(:identifier).returns('/a/b/')
    layouts[3].stubs(:identifier).returns('/a/')

    # Get expectations
    expectations = {
      0 => 'd',
      1 => 'b', # never used! not c, because b takes priority
      2 => 'b',
      3 => 'a',
    }

    # Check
    expectations.each_pair do |num, char|
      filter_and_args = rules_collection.filter_for_layout(layouts[num])
      refute_nil(filter_and_args)
      assert_equal(char, filter_and_args[1][:char])
    end
  end
end
