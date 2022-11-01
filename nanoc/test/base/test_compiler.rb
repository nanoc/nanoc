# frozen_string_literal: true

require 'helper'

class Nanoc::Core::CompilerTest < Nanoc::TestCase
  def test_compile_rep_should_write_proper_snapshots_real
    with_site do |_site|
      File.write('content/moo.txt', '<%= 1 %> <%%= 2 %> <%%%= 3 %>')
      File.write('layouts/default.erb', 'head <%= yield %> foot')

      File.open('Rules', 'w') do |io|
        io.write "compile '/**/*' do\n"
        io.write "  filter :erb\n"
        io.write "  filter :erb\n"
        io.write "  layout 'default'\n"
        io.write "  filter :erb\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*', snapshot: :raw do\n"
        io.write "  '/moo-raw.txt'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*', snapshot: :pre do\n"
        io.write "  '/moo-pre.txt'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*', snapshot: :post do\n"
        io.write "  '/moo-post.txt'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*' do\n"
        io.write "  '/moo-last.txt'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '/**/*', :erb\n"
      end

      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert File.file?('output/moo-raw.txt')
      assert File.file?('output/moo-pre.txt')
      assert File.file?('output/moo-post.txt')
      assert File.file?('output/moo-last.txt')
      assert_equal '<%= 1 %> <%%= 2 %> <%%%= 3 %>', File.read('output/moo-raw.txt')
      assert_equal '1 2 <%= 3 %>',                  File.read('output/moo-pre.txt')
      assert_equal 'head 1 2 3 foot',               File.read('output/moo-post.txt')
      assert_equal 'head 1 2 3 foot',               File.read('output/moo-last.txt')
    end
  end

  def test_compile_with_no_reps
    with_site do |site|
      Nanoc::Core::Compiler.compile(site)

      assert_predicate Dir['output/*'], :empty?
    end
  end

  def test_compile_with_one_rep
    with_site do |_site|
      File.write('content/index.html', 'o hello')

      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert_equal(1, Dir['output/*'].size)
      assert File.file?('output/index.html')
      assert_equal('o hello', File.read('output/index.html'))
    end
  end

  def test_compile_with_two_independent_reps
    with_site do |_site|
      File.write('content/foo.html', 'o hai')
      File.write('content/bar.html', 'o bai')

      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert_equal(2, Dir['output/*'].size)
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert_equal('o hai', File.read('output/foo/index.html'))
      assert_equal('o bai', File.read('output/bar/index.html'))
    end
  end

  def test_compile_with_two_dependent_reps
    with_site(compilation_rule_content: 'filter :erb') do |_site|
      File.write('content/foo.html', '<%= @items.find { |i| i.identifier == "/bar/" }.compiled_content %>!!!')
      File.write('content/bar.html', 'manatee')

      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      assert_equal(2, Dir['output/*'].size)
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert_equal('manatee!!!', File.read('output/foo/index.html'))
      assert_equal('manatee', File.read('output/bar/index.html'))
    end
  end

  def test_compile_with_two_mutually_dependent_reps
    with_site(compilation_rule_content: 'filter :erb') do |_site|
      File.write('content/foo.html', '<%= @items.find { |i| i.identifier == "/bar/" }.compiled_content %>')
      File.write('content/bar.html', '<%= @items.find { |i| i.identifier == "/foo/" }.compiled_content %>')

      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      assert_raises Nanoc::Core::Errors::DependencyCycle do
        Nanoc::Core::Compiler.compile(site)
      end
    end
  end

  def test_disallow_routes_not_starting_with_slash
    # Create site
    Nanoc::CLI.run %w[create_site bar]

    FileUtils.cd('bar') do
      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '/**/*' do\n"
        io.write "  layout 'default'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*' do\n"
        io.write "  'index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '/**/*', :erb\n"
      end

      # Create site
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      error = assert_raises(Nanoc::Error) do
        Nanoc::Core::Compiler.compile(site)
      end

      assert_match(/^The path returned for the.*does not start with a slash. Please ensure that all routing rules return a path that starts with a slash./, error.message)
    end
  end

  def test_include_compiled_content_of_active_item_at_previous_snapshot
    with_site do |_site|
      # Create item
      File.write('content/index.html', '[<%= @item.compiled_content(:snapshot => :aaa) %>]')

      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  snapshot :aaa\n"
        io.write "  filter :erb\n"
        io.write "  filter :erb\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check
      assert_equal '[[[<%= @item.compiled_content(:snapshot => :aaa) %>]]]', File.read('output/index.html')
    end
  end

  def test_mutually_include_compiled_content_at_previous_snapshot
    with_site do |_site|
      # Create items
      File.write('content/a.html', '[<%= @items.find { |i| i.identifier == "/z/" }.compiled_content(:snapshot => :guts) %>]')
      File.write('content/z.html', 'stuff')

      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  snapshot :guts\n"
        io.write "  filter :erb\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  item.identifier + 'index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check
      assert_equal '[stuff]', File.read('output/a/index.html')
      assert_equal 'stuff', File.read('output/z/index.html')
    end
  end

  def test_tmp_text_items_are_removed_after_compilation
    with_site do |_site|
      # Create item
      File.write('content/index.html', 'stuff')

      # Compile
      site = Nanoc::Core::SiteLoader.new.new_from_cwd
      Nanoc::Core::Compiler.compile(site)

      # Check
      assert_predicate Dir['tmp/text_items/*'], :empty?
    end
  end
end
