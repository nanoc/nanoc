# encoding: utf-8

class Nanoc::RulesCollectionTest < Nanoc::TestCase

  def new_snapshot_store
    Nanoc::SnapshotStore::InMemory.new
  end

  def test_compilation_rule_for
    # Create rules
    rules = Nanoc::RulesCollection.new
    dsl = Nanoc::CompilerDSL.new(rules)
    dsl.compile '/wrong' do ; end
    dsl.compile '/almost',  :rep => :left  do ; end
    dsl.compile '/correct', :rep => :right do ; end

    # Mock items and reps
    item = Nanoc::Item.new('stuff', {}, '/correct')
    rep = Nanoc::ItemRep.new(item, :right, :snapshot_store => self.new_snapshot_store)

    # Test
    assert_equal rules.item_compilation_rules[2], rules.compilation_rule_for(rep)
  end

  def test_filter_for_layout_with_existant_layout
    # Create rules
    rules = Nanoc::RulesCollection.new
    dsl = Nanoc::CompilerDSL.new(rules)
    dsl.layout '/blah', :erb, { :foo => 'bar' }

    # Mock layout
    layout = Nanoc::Layout.new('stuff', {}, '/blah')

    # Test
    assert_equal([ :erb, { :foo => 'bar' } ], rules.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_nonexistant_layout
    # Create rules
    rules = Nanoc::RulesCollection.new
    dsl = Nanoc::CompilerDSL.new(rules)
    dsl.layout '/blah', :erb

    # Mock layout
    layout = Nanoc::Layout.new('stuff', {}, '/blaasdljfklasghlksdfh')

    # Test
    assert_equal(nil, rules.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_many_layouts
    # Create rules
    rules = Nanoc::RulesCollection.new
    dsl = Nanoc::CompilerDSL.new(rules)
    dsl.layout '/a/b/c/**/*', :erb, { :char => 'd' }
    dsl.layout '/a/**/*',     :erb, { :char => 'b' }
    dsl.layout '/a/b/**/*',   :erb, { :char => 'c' } # never used!
    dsl.layout '/**/*',       :erb, { :char => 'a' }

    # Mock layouts
    layouts = [
      Nanoc::Layout.new('one', {}, '/a/b/c/d'),
      Nanoc::Layout.new('one', {}, '/a/b/c'),
      Nanoc::Layout.new('one', {}, '/a/b'),
      Nanoc::Layout.new('one', {}, '/a')
    ]

    # Get expectations
    expectations = {
      0 => 'd',
      1 => 'b', # never used! not c, because b takes priority
      2 => 'b',
      3 => 'a'
    }

    # Check
    expectations.each_pair do |num, char|
      filter_and_args = rules.filter_for_layout(layouts[num])
      refute_nil(filter_and_args)
      assert_equal(char, filter_and_args[1][:char])
    end
  end

end
