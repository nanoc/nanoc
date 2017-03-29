require 'helper'

class Nanoc::Int::OutdatednessCheckerTest < Nanoc::TestCase
  def test_not_outdated
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('lib/stuff.rb', 'w') { |io| io.write('$foo = 123') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_nil outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_item_checksum_nil
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('lib/stuff.rb', 'w') { |io| io.write('$foo = 123') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Delete checksums
    with_site(name: 'foo') do |_site|
      Dir['tmp/nanoc/*/checksums'].each { |fn| FileUtils.rm(fn) }
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::ContentModified, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_compiled_file_doesnt_exist
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('lib/stuff.rb', 'w') { |io| io.write('$foo = 123') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Delete old item
    FileUtils.cd('foo') do
      FileUtils.rm_rf('output/index.html')
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::NotWritten, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_item_content_checksum_is_different
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('content/new.html', 'w') { |io| io.write('o hello too') }
      File.open('lib/stuff.rb', 'w') { |io| io.write('$foo = 123') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Update item
    FileUtils.cd('foo') do
      File.open('content/new.html', 'w') { |io| io.write('o hello DIFFERENT!!!') }
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/new/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::ContentModified, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_item_attributes_checksum_is_different
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('content/new.html', 'w') { |io| io.write('o hello too') }
      File.open('lib/stuff.rb', 'w') { |io| io.write('$foo = 123') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Update item
    FileUtils.cd('foo') do
      File.open('content/new.html', 'w') { |io| io.write("---\ntitle: donkey\n---\no hello too") }
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/new/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::AttributesModified, outdatedness_checker.outdatedness_reasons_for(rep).first.class
    end
  end

  def test_outdated_if_dependent_layout_outdated
    # Compile once
    with_site(name: 'foo', compilation_rule_content: 'layout "/default/"', has_layout: true) do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('layouts/default.html', 'w') { |io| io.write('!!! <%= yield %> !!!') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Change layout
    FileUtils.cd('foo') do
      File.open('layouts/default.html', 'w') { |io| io.write('!!! <%= yield %> !!! different') }
    end

    # Check
    with_site(name: 'foo') do |site|
      # FIXME: ugly fugly hack
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores

      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::DependenciesOutdated, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_dependent_item_outdated
    # Compile once
    with_site(name: 'foo', compilation_rule_content: 'filter :erb') do |site|
      File.open('content/a.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/b/" }.compiled_content %>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('stuff')
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Change item
    FileUtils.cd('foo') do
      File.open('content/b.html', 'w') do |io|
        io.write('stuff different!!!')
      end
    end

    # Check
    with_site(name: 'foo') do |site|
      # FIXME: ugly fugly hack
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores

      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/a/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::DependenciesOutdated, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_dependent_item_outdated_chained
    # Compile once
    with_site(name: 'foo', compilation_rule_content: 'filter :erb') do |site|
      File.open('content/a.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/b/" }.compiled_content %> aaa')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/c/" }.compiled_content %> bbb')
      end
      File.open('content/c.html', 'w') do |io|
        io.write('stuff')
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Change item
    FileUtils.cd('foo') do
      File.open('content/c.html', 'w') do |io|
        io.write('stuff different!!!')
      end
    end

    # Check
    with_site(name: 'foo') do |site|
      # FIXME: ugly fugly hack
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores

      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/a/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::DependenciesOutdated, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_dependent_item_removed
    # Compile once
    with_site(name: 'foo', compilation_rule_content: 'filter :erb') do |site|
      File.open('content/a.html', 'w') do |io|
        io.write('<% @items.select { |i| i.identifier != @item.identifier }.each do |i| %>')
        io.write('  <%= i.compiled_content %>')
        io.write('<% end %>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('stuff')
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Delete item
    FileUtils.cd('foo') do
      FileUtils.rm_rf('content/b.html')
    end

    # Check
    with_site(name: 'foo') do |site|
      # FIXME: ugly fugly hack
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores

      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/a/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::DependenciesOutdated, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_dependent_item_added
    # Compile once
    with_site(name: 'foo', compilation_rule_content: 'filter :erb') do |site|
      File.open('content/a.html', 'w') do |io|
        io.write('<% @items.select { |i| i.identifier != @item.identifier }.each do |i| %>')
        io.write('  <%= i.compiled_content %>')
        io.write('<% end %>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('stuff')
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Add item
    FileUtils.cd('foo') do
      File.open('content/z.html', 'w') do |io|
        io.write('moar stuff')
      end
    end

    # Check
    with_site(name: 'foo') do |site|
      # FIXME: ugly fugly hack
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores

      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/a/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::DependenciesOutdated, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  # TODO: make sure outdatedness of non-outdated items is correct

  def test_outdated_if_code_snippets_outdated
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Change code
    FileUtils.cd('foo') do
      File.open('lib/moo.rb', 'w') { |io| io.write('def moo ; puts "moo" ; end') }
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::CodeSnippetsModified, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_config_outdated
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Change code
    FileUtils.cd('foo') do
      File.open('nanoc.yaml', 'w') do |io|
        io << 'awesome: true' << "\n"
        io << 'string_pattern_type: legacy' << "\n"
        io << 'data_sources:' << "\n"
        io << '  -' << "\n"
        io << '    type: filesystem' << "\n"
        io << '    identifier_type: legacy' << "\n"
      end
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::ConfigurationModified, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_not_outdated_if_irrelevant_rule_modified
    # Compile once
    with_site(name: 'foo') do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Change code
    FileUtils.cd('foo') do
      File.open('Rules', 'a') { |io| io.write('layout "/moo/", :haml') }
    end

    # Check
    with_site(name: 'foo') do |site|
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_nil outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_outdated_if_relevant_rule_modified
    # Create site
    with_site(name: 'foo') do |_site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('Rules', 'w') do |io|
        io.write("compile '/' do\n")
        io.write("  filter :erb\n")
        io.write("end\n")
        io.write("\n")
        io.write("route '/' do\n")
        io.write("  '/index.html'\n")
        io.write("end\n")
      end
    end

    # Compile once
    FileUtils.cd('foo') do
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Modify rules
    FileUtils.cd('foo') do
      File.open('Rules', 'w') do |io|
        io.write("compile '/' do\n")
        io.write("end\n")
        io.write("\n")
        io.write("route '/' do\n")
        io.write("  '/index.html'\n")
        io.write("end\n")
      end
    end

    # Check
    FileUtils.cd('foo') do
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compiler.build_reps
      site.compiler.load_stores
      outdatedness_checker = site.compiler.send :outdatedness_checker
      rep = site.compiler.reps[site.items.find { |i| i.identifier == '/' }][0]
      assert_equal ::Nanoc::Int::OutdatednessReasons::RulesModified, outdatedness_checker.outdatedness_reasons_for(rep).first
    end
  end

  def test_items_in_rules_should_not_cause_outdatedness
    # Create site
    with_site(name: 'foo') do |_site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('Rules', 'w') do |io|
        io.write("compile '/' do\n")
        io.write("  filter :erb, :stuff => @items\n")
        io.write("end\n")
        io.write("\n")
        io.write("route '/' do\n")
        io.write("  '/index.html'\n")
        io.write("end\n")
      end
    end

    # Compile
    FileUtils.cd('foo') do
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Assert not outdated
    FileUtils.cd('foo') do
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      outdatedness_checker = site.compiler.outdatedness_checker
      site.items.each do |item|
        refute outdatedness_checker.outdated?(item), 'item should not be outdated'
      end
    end
  end

  def test_non_serializable_parameters_in_rules_should_be_allowed
    # Create site
    with_site(name: 'foo') do |_site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }
      File.open('Rules', 'w') do |io|
        io.write("compile '/' do\n")
        io.write("  c = Class.new {}\n")
        io.write("  def c.inspect ; 'I am so classy' ; end\n")
        io.write("  filter :erb, :stuff => c, :more => 123\n")
        io.write("end\n")
        io.write("\n")
        io.write("route '/' do\n")
        io.write("  '/index.html'\n")
        io.write("end\n")
      end
    end

    # Compile
    FileUtils.cd('foo') do
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end

    # Assert not outdated
    FileUtils.cd('foo') do
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      outdatedness_checker = site.compiler.outdatedness_checker
      site.items.each do |item|
        refute outdatedness_checker.outdated?(item), 'item should not be outdated'
      end
    end
  end
end
