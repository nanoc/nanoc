require 'helper'

class Nanoc::Int::CompilerTest < Nanoc::TestCase
  def test_compile_rep_should_write_proper_snapshots_real
    with_site do |site|
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

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

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
      site.compile

      assert Dir['output/*'].empty?
    end
  end

  def test_compile_with_one_rep
    with_site do |site|
      File.open('content/index.html', 'w') { |io| io.write('o hello') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      assert Dir['output/*'].size == 1
      assert File.file?('output/index.html')
      assert File.read('output/index.html') == 'o hello'
    end
  end

  def test_compile_with_two_independent_reps
    with_site do |site|
      File.open('content/foo.html', 'w') { |io| io.write('o hai') }
      File.open('content/bar.html', 'w') { |io| io.write('o bai') }

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      assert Dir['output/*'].size == 2
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert File.read('output/foo/index.html') == 'o hai'
      assert File.read('output/bar/index.html') == 'o bai'
    end
  end

  def test_compile_with_two_dependent_reps
    with_site(compilation_rule_content: 'filter :erb') do |site|
      File.open('content/foo.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/bar/" }.compiled_content %>!!!')
      end
      File.open('content/bar.html', 'w') do |io|
        io.write('manatee')
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      assert Dir['output/*'].size == 2
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert File.read('output/foo/index.html') == 'manatee!!!'
      assert File.read('output/bar/index.html') == 'manatee'
    end
  end

  def test_compile_with_two_mutually_dependent_reps
    with_site(compilation_rule_content: 'filter :erb') do |site|
      File.open('content/foo.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/bar/" }.compiled_content %>')
      end
      File.open('content/bar.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/foo/" }.compiled_content %>')
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      assert_raises Nanoc::Int::Errors::DependencyCycle do
        site.compile
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
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      error = assert_raises(Nanoc::Error) do
        site.compile
      end
      assert_match(/^The path returned for the.*does not start with a slash. Please ensure that all routing rules return a path that starts with a slash./, error.message)
    end
  end

  def test_disallow_duplicate_routes
    # Create site
    Nanoc::CLI.run %w[create_site bar]

    FileUtils.cd('bar') do
      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '/**/*' do\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
      end

      # Create files
      File.write('content/foo.html', 'asdf')
      File.write('content/bar.html', 'asdf')

      # Create site
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      assert_raises(Nanoc::Int::ItemRepRouter::IdenticalRoutesError) do
        site.compile
      end
    end
  end

  def test_disallow_multiple_snapshots_with_the_same_name
    # Create site
    Nanoc::CLI.run %w[create_site bar]

    FileUtils.cd('bar') do
      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '/**/*' do\n"
        io.write "  snapshot :aaa\n"
        io.write "  snapshot :aaa\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*' do\n"
        io.write "  item.identifier.to_s\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '/**/*', :erb\n"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      assert_raises Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName do
        site.compile
      end
    end
  end

  def test_include_compiled_content_of_active_item_at_previous_snapshot
    with_site do |site|
      # Create item
      File.open('content/index.html', 'w') do |io|
        io.write('[<%= @item.compiled_content(:snapshot => :aaa) %>]')
      end

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
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert_equal '[[[<%= @item.compiled_content(:snapshot => :aaa) %>]]]', File.read('output/index.html')
    end
  end

  def test_mutually_include_compiled_content_at_previous_snapshot
    with_site do |site|
      # Create items
      File.open('content/a.html', 'w') do |io|
        io.write('[<%= @items.find { |i| i.identifier == "/z/" }.compiled_content(:snapshot => :guts) %>]')
      end
      File.open('content/z.html', 'w') do |io|
        io.write('stuff')
      end

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
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert_equal '[stuff]', File.read('output/a/index.html')
      assert_equal 'stuff', File.read('output/z/index.html')
    end
  end

  def test_layout_with_extra_filter_args
    with_site do |site|
      # Create item
      File.open('content/index.html', 'w') do |io|
        io.write('This is <%= @foo %>.')
      end

      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  filter :erb, :locals => { :foo => 123 }\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert_equal 'This is 123.', File.read('output/index.html')
    end
  end

  def test_change_routing_rule_and_recompile
    with_site do |site|
      # Create items
      File.open('content/a.html', 'w') do |io|
        io.write('<h1>A</h1>')
      end
      File.open('content/b.html', 'w') do |io|
        io.write('<h1>B</h1>')
      end

      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/a/' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  nil\n"
        io.write "end\n"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert_equal '<h1>A</h1>', File.read('output/index.html')

      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/b/' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  nil\n"
        io.write "end\n"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert_equal '<h1>B</h1>', File.read('output/index.html')
    end
  end

  def test_rep_assigns
    with_site do |site|
      # Create item
      File.open('content/index.html', 'w') do |io|
        io.write('@rep.name = <%= @rep.name %> - @item_rep.name = <%= @item_rep.name %>')
      end

      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  if @rep.name == :default && @item_rep.name == :default\n"
        io.write "    filter :erb\n"
        io.write "  end\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert_equal '@rep.name = default - @item_rep.name = default', File.read('output/index.html')
    end
  end

  def test_unfiltered_binary_item_should_not_be_moved_outside_content
    with_site do
      File.open('content/blah.dat', 'w') { |io| io.write('o hello') }

      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  item.identifier.chop + '.' + item[:extension]\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      assert_equal Set.new(%w[content/blah.dat]), Set.new(Dir['content/*'])
      assert_equal Set.new(%w[output/blah.dat]), Set.new(Dir['output/*'])
    end
  end

  def test_tmp_text_items_are_removed_after_compilation
    with_site do |site|
      # Create item
      File.open('content/index.html', 'w') do |io|
        io.write('stuff')
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check
      assert Dir['tmp/text_items/*'].empty?
    end
  end

  def test_find_layouts_by_glob
    Nanoc::CLI.run %w[create_site bar]
    FileUtils.cd('bar') do
      File.open('Rules', 'w') do |io|
        io.write "compile '/**/*' do\n"
        io.write "  layout '/default.*'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '/**/*' do\n"
        io.write "  item.identifier.to_s\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '/**/*', :erb\n"
      end

      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile
    end
  end
end
