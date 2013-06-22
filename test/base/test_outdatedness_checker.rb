# encoding: utf-8

class Nanoc::OutdatednessCheckerTest < Nanoc::TestCase

  def test_not_outdated
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.write('lib/stuff.rb', '$foo = 123')

      compile_site_here
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      rep = compiler.item_rep_store.reps[0]
      assert_nil outdatedness_checker.outdatedness_reason_for(rep)
    end
  end

  def test_outdated_if_item_checksum_nil
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.write('lib/stuff.rb', '$foo = 123')

      compile_site_here
    end

    # Delete checksums
    in_site(:name => 'foo') do
      FileUtils.rm('tmp/checksums')
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      assert_equal ::Nanoc::OutdatednessReasons::NotEnoughData,
        outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_outdated_if_compiled_file_doesnt_exist
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.write('lib/stuff.rb', '$foo = 123')

      compile_site_here
    end

    # Delete old item
    FileUtils.rm_rf('foo/output/index.html')

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      # This fails because the new item rep hasn't been compiled yet, and
      # therefore hasn't any raw paths without snapshot assigned :/
      assert_equal ::Nanoc::OutdatednessReasons::NotWritten,
        outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_outdated_if_item_checksum_is_different
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.write('content/new.html', 'o hello too')
      File.write('lib/stuff.rb', '$foo = 123')

      compile_site_here
    end

    # Create new item
    FileUtils.cd('foo') do
      File.write('content/new.html', 'o hello DIFFERENT!!!')
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      item = site.items.find { |i| i.identifier == '/new.html' }
      rep = compiler.item_rep_store.reps_for_item(item)[0]
      assert_equal ::Nanoc::OutdatednessReasons::SourceModified,
        outdatedness_checker.outdatedness_reason_for(rep)
    end
  end

  def test_outdated_if_dependent_layout_outdated
    # Compile once
    in_site(:name => 'foo', :compilation_rule_content => 'layout "/default.html"', :has_layout => true) do
      File.write('content/index.html', 'o hello')
      File.write('layouts/default.html', '!!! <%= yield %> !!!')

      compile_site_here
    end

    # Change layout
    FileUtils.cd('foo') do
      File.write('layouts/default.html', '!!! <%= yield %> !!! different')
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      assert_equal ::Nanoc::OutdatednessReasons::DependenciesOutdated,
        outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_outdated_if_dependent_item_outdated
    # Compile once
    in_site(:name => 'foo', :compilation_rule_content => 'filter :erb') do
      File.open('content/a.html', 'w') do |io|
        io.write('<%= @items["/b.html"].compiled_content %>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('stuff')
      end

      compile_site_here
    end

    # Change item
    FileUtils.cd('foo') do
      File.open('content/b.html', 'w') do |io|
        io.write('stuff different!!!')
      end
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      item = site.items.find { |i| i.identifier == '/a.html' }
      rep = compiler.item_rep_store.reps_for_item(item)[0]
      assert_equal ::Nanoc::OutdatednessReasons::DependenciesOutdated,
        outdatedness_checker.outdatedness_reason_for(rep)
    end
  end

  def test_outdated_if_dependent_item_outdated_chained
    # Compile once
    in_site(:name => 'foo', :compilation_rule_content => 'filter :erb') do
      File.open('content/a.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/b.html" }.compiled_content %> aaa')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/c.html" }.compiled_content %> bbb')
      end
      File.open('content/c.html', 'w') do |io|
        io.write('stuff')
      end

      compile_site_here
    end

    # Change item
    FileUtils.cd('foo') do
      File.open('content/c.html', 'w') do |io|
        io.write('stuff different!!!')
      end
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      item = site.items.find { |i| i.identifier == '/a.html' }
      rep = compiler.item_rep_store.reps_for_item(item)[0]
      assert_equal ::Nanoc::OutdatednessReasons::DependenciesOutdated,
        outdatedness_checker.outdatedness_reason_for(rep)
    end
  end

  def test_outdated_if_dependent_item_removed
    # Compile once
    in_site(:name => 'foo', :compilation_rule_content => 'filter :erb') do
      File.open('content/a.html', 'w') do |io|
        io.write('<% @items.select { |i| i.identifier != @item.identifier }.each do |i| %>')
        io.write('  <%= i.compiled_content %>')
        io.write('<% end %>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('stuff')
      end

      compile_site_here
    end

    # Delete item
    FileUtils.cd('foo') do
      FileUtils.rm_rf('content/b.html')
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      item = site.items.find { |i| i.identifier == '/a.html' }
      rep = compiler.item_rep_store.reps_for_item(item)[0]
      assert_equal ::Nanoc::OutdatednessReasons::DependenciesOutdated,
        outdatedness_checker.outdatedness_reason_for(rep)
    end
  end

  def test_outdated_if_dependent_item_added
    # Compile once
    in_site(:name => 'foo', :compilation_rule_content => 'filter :erb') do
      File.open('content/a.html', 'w') do |io|
        io.write('<% @items.select { |i| i.identifier != @item.identifier }.each do |i| %>')
        io.write('  <%= i.compiled_content %>')
        io.write('<% end %>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('stuff')
      end

      compile_site_here
    end

    # Add item
    FileUtils.cd('foo') do
      File.open('content/z.html', 'w') do |io|
        io.write('moar stuff')
      end
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      item = site.items.find { |i| i.identifier == '/a.html' }
      rep = compiler.item_rep_store.reps_for_item(item)[0]
      assert_equal ::Nanoc::OutdatednessReasons::DependenciesOutdated,
        outdatedness_checker.outdatedness_reason_for(rep)
    end
  end

  # TODO make sure outdatedness of non-outdated items is correct

  def test_outdated_if_code_snippets_outdated
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')

      compile_site_here
    end

    # Change code
    FileUtils.cd('foo') do
      File.write('lib/moo.rb', 'def moo ; puts "moo" ; end')
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      assert_equal ::Nanoc::OutdatednessReasons::CodeSnippetsModified,
        outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_outdated_if_config_outdated
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')

      compile_site_here
    end

    # Change code
    FileUtils.cd('foo') do
      File.write('nanoc.yaml', 'awesome: true')
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      assert_equal ::Nanoc::OutdatednessReasons::ConfigurationModified,
        outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_not_outdated_if_irrelevant_rule_modified
    # Compile once
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')

      compile_site_here
    end

    # Change code
    FileUtils.cd('foo') do
      File.open('Rules', 'a') { |io| io.write('layout "/moo/", :haml') }
    end

    # Check
    in_site(:name => 'foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      assert_nil outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_outdated_if_relevant_rule_modified
    # Create site
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.open('Rules', 'w') do |io|
        io.write("compile '/index.html' do\n")
        io.write("  filter :erb\n")
        io.write("  write '/index.html'\n")
        io.write("end\n")
      end

      compile_site_here
    end

    # Modify rules
    FileUtils.cd('foo') do
      File.open('Rules', 'w') do |io|
        io.write("compile '/index.html' do\n")
        io.write("  write '/index.html'\n")
        io.write("end\n")
      end
    end

    # Check
    FileUtils.cd('foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.send :outdatedness_checker
      reps = compiler.item_rep_store.reps
      assert_equal 1, reps.size
      assert_equal ::Nanoc::OutdatednessReasons::RulesModified,
        outdatedness_checker.outdatedness_reason_for(reps[0])
    end
  end

  def test_items_in_rules_should_not_cause_outdatedness
    # Create site
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.open('Rules', 'w') do |io|
        io.write("compile '/index.html' do\n")
        io.write("  filter :erb, :stuff => @items\n")
        io.write("  write '/index.html'\n")
        io.write("end\n")
      end
    end

    # Compile
    FileUtils.cd('foo') do
      compile_site_here
    end

    # Assert not outdated
    FileUtils.cd('foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.outdatedness_checker
      site.items.each do |item|
        assert_nil outdatedness_checker.outdatedness_reason_for(item)
      end
    end
  end

  def test_non_serializable_parameters_in_rules_should_be_allowed
    # Create site
    in_site(:name => 'foo') do
      File.write('content/index.html', 'o hello')
      File.open('Rules', 'w') do |io|
        io.write("compile '/index.html' do\n")
        io.write("  c = Class.new {}\n")
        io.write("  def c.inspect ; 'I am so classy' ; end\n")
        io.write("  filter :erb, :stuff => c, :more => 123\n")
        io.write("  write '/index.html'\n")
        io.write("end\n")
      end
    end

    # Compile
    FileUtils.cd('foo') do
      compile_site_here
    end

    # Assert not outdated
    FileUtils.cd('foo') do
      site = site_here
      compiler = Nanoc::Compiler.new(site)
      compiler.load
      outdatedness_checker = compiler.outdatedness_checker
      site.items.each do |item|
        refute outdatedness_checker.outdated?(item), "item should not be outdated"
      end
    end
  end

end
