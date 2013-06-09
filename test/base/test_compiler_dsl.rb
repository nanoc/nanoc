# encoding: utf-8

class Nanoc::CompilerDSLTest < Nanoc::TestCase

  def setup
    super
    @rules_collection = Nanoc::RulesCollection.new
    @compiler_dsl = Nanoc::CompilerDSL.new(@rules_collection)
  end

  def test_compile
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def test_write
    with_site do
      # Create rules
      File.write('Rules', <<EOS)
compile '/**/*' do
  write '/raw.txt'
  filter :erb
  write '/filtered.txt'
end
EOS

      # Create items
      assert Dir['content/*'].empty?
      File.write('content/input.txt', 'A <%= "X" %> B')

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert File.file?('output/raw.txt')
      assert File.file?('output/filtered.txt')
      assert_equal 'A <%= "X" %> B', File.read('output/raw.txt')
      assert_equal 'A X B',          File.read('output/filtered.txt')
    end
  end

  def test_write_and_snapshot
    with_site do
      # Create rules
      File.write('Rules', <<EOS)
compile '/**/*' do
  write '/foo.txt', :snapshot => :foo
  filter :erb
  write '/bar.txt'
end
EOS

      # Create items
      assert Dir['content/*'].empty?
      File.write('content/input.txt', 'stuff <%= "goes" %> here')

      # Compile
      site = Nanoc::Site.new('.')
      site.compile

      # Check paths
      assert File.file?('output/foo.txt')
      assert File.file?('output/bar.txt')
      assert_equal 'stuff <%= "goes" %> here', File.read('output/foo.txt')
      assert_equal 'stuff goes here',          File.read('output/bar.txt')

      # Check snapshot
      item = Nanoc::ItemProxy.new(site.items[0], site.compiler.item_rep_store)
      assert_equal 'stuff <%= "goes" %> here', item.compiled_content(snapshot: :foo)
      assert_equal 'stuff goes here',          item.compiled_content(snapshot: :last)
    end
  end

  def new_snapshot_store
    Nanoc::SnapshotStore::InMemory.new
  end

  def test_include_rules
    with_site do
      # Create rep
      item = Nanoc::Item.new('foo', { :extension => 'bar' }, '/foo.bar')
      rep  = Nanoc::ItemRep.new(item, :default, :snapshot_store => self.new_snapshot_store)

      # Create a bonus rules file
      File.write('more_rules.rb', "compile '/foo.*' do end")

      # Create other necessary stuff
      site = Nanoc::Site.new('.')
      site.items << item
      dsl = Nanoc::CompilerDSL.new(site.compiler.rules_collection)

      # Include rules
      dsl.include_rules 'more_rules'

      # Check that the rule made it into the collection
      refute_nil site.compiler.rules_collection.compilation_rule_for(rep)
    end
  end

  def test_dsl_has_no_access_to_compiler
    assert_raises(NameError) do
      @compiler_dsl.instance_eval { compiler }
    end
  end

end
