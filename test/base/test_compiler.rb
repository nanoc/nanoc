# encoding: utf-8

class Nanoc::CompilerTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_compilation_rule_for
    # Mock rules
    rules = [ mock, mock, mock ]
    rules[0].expects(:applicable_to?).returns(false)
    rules[1].expects(:applicable_to?).returns(true)
    rules[1].expects(:rep_name).returns('wrong')
    rules[2].expects(:applicable_to?).returns(true)
    rules[2].expects(:rep_name).returns('right')

    # Create compiler
    compiler = Nanoc::Compiler.new(nil)
    compiler.rules_collection.instance_eval { @item_compilation_rules = rules }

    # Mock rep
    rep = mock
    rep.stubs(:name).returns('right')
    item = mock
    rep.stubs(:item).returns(item)

    # Test
    assert_equal rules[2], compiler.rules_collection.compilation_rule_for(rep)
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
    compiler = Nanoc::Compiler.new(nil)
    compiler.rules_collection.instance_eval { @item_routing_rules = rules }

    # Mock rep
    rep = mock
    rep.stubs(:name).returns('right')
    item = mock
    rep.stubs(:item).returns(item)

    # Test
    assert_equal rules[2], compiler.rules_collection.routing_rule_for(rep)
  end

  def test_filter_for_layout_with_existant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.rules_collection.layout_filter_mapping[/.*/] = [ :erb, { :foo => 'bar' } ]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal([ :erb, { :foo => 'bar' } ], compiler.rules_collection.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_existant_layout_and_unknown_filter
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.rules_collection.layout_filter_mapping[/.*/] = [ :some_unknown_filter, { :foo => 'bar' } ]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/some_layout/')

    # Check
    assert_equal([ :some_unknown_filter, { :foo => 'bar' } ], compiler.rules_collection.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_nonexistant_layout
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.rules_collection.layout_filter_mapping[%r{^/foo/$}] = [ :erb, { :foo => 'bar' } ]

    # Mock layout
    layout = MiniTest::Mock.new
    layout.expect(:identifier, '/bar/')

    # Check
    assert_equal(nil, compiler.rules_collection.filter_for_layout(layout))
  end

  def test_filter_for_layout_with_many_layouts
    # Mock site
    site = mock

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.rules_collection.layout_filter_mapping[%r{^/a/b/c/.*/$}] = [ :erb, { :char => 'd' } ]
    compiler.rules_collection.layout_filter_mapping[%r{^/a/.*/$}]     = [ :erb, { :char => 'b' } ]
    compiler.rules_collection.layout_filter_mapping[%r{^/a/b/.*/$}]   = [ :erb, { :char => 'c' } ] # never used!
    compiler.rules_collection.layout_filter_mapping[%r{^/.*/$}]       = [ :erb, { :char => 'a' } ]

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
      filter_and_args = compiler.rules_collection.filter_for_layout(layouts[num])
      refute_nil(filter_and_args)
      assert_equal(char, filter_and_args[1][:char])
    end
  end

  def test_compile_rep_should_write_proper_snapshots
    # Mock rep
    item = Nanoc::Item.new('<%= 1 %> <%%= 2 %> <%%%= 3 %>', {}, '/moo/')
    rep  = Nanoc::ItemRep.new(item, :blah)

    # Set snapshot filenames
    rep.raw_paths = {
      :raw  => 'raw.txt',
      :pre  => 'pre.txt',
      :post => 'post.txt',
      :last => 'last.txt'
    }

    # Create rule
    rule_block = proc do
      filter :erb
      filter :erb
      layout '/blah/'
      filter :erb
    end
    rule = Nanoc::Rule.new(/blah/, :meh, rule_block)

    # Create layout
    layout = Nanoc::Layout.new('head <%= yield %> foot', {}, '/blah/')

    # Create site
    site = mock
    site.stubs(:config).returns({})
    site.stubs(:items).returns([])
    site.stubs(:layouts).returns([ layout ])

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.rules_collection.expects(:compilation_rule_for).times(2).with(rep).returns(rule)
    compiler.rules_collection.layout_filter_mapping[%r{^/blah/$}] = [ :erb, {} ]
    site.stubs(:compiler).returns(compiler)

    # Compile
    compiler.send(:compile_rep, rep)

    # Test
    assert File.file?('raw.txt')
    assert File.file?('pre.txt')
    assert File.file?('post.txt')
    assert File.file?('last.txt')
    assert_equal '<%= 1 %> <%%= 2 %> <%%%= 3 %>', File.read('raw.txt')
    assert_equal '1 2 <%= 3 %>',                  File.read('pre.txt')
    assert_equal 'head 1 2 3 foot',               File.read('post.txt')
    assert_equal 'head 1 2 3 foot',               File.read('last.txt')
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

      site.compile

      assert Dir['output/*'].size == 2
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert File.read('output/foo/index.html') == 'o hai'
      assert File.read('output/bar/index.html') == 'o bai'
    end
  end

  def test_compile_with_two_dependent_reps
    with_site(:compilation_rule_content => 'filter :erb') do |site|
      File.open('content/foo.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/bar/" }.compiled_content %>!!!')
      end
      File.open('content/bar.html', 'w') do |io|
        io.write('manatee')
      end

      site.compile

      assert Dir['output/*'].size == 2
      assert File.file?('output/foo/index.html')
      assert File.file?('output/bar/index.html')
      assert File.read('output/foo/index.html') == 'manatee!!!'
      assert File.read('output/bar/index.html') == 'manatee'
    end
  end

  def test_compile_with_two_mutually_dependent_reps
    with_site(:compilation_rule_content => 'filter :erb') do |site|
      File.open('content/foo.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/bar/" }.compiled_content %>')
      end
      File.open('content/bar.html', 'w') do |io|
        io.write('<%= @items.find { |i| i.identifier == "/foo/" }.compiled_content %>')
      end

      assert_raises Nanoc::Errors::RecursiveCompilation do
        site.compile
      end
    end
  end

  def test_disallow_routes_not_starting_with_slash
    # Create site
    Nanoc::CLI.run %w( create_site bar)

    FileUtils.cd('bar') do
      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  layout 'default'\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  'index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      # Create site
      site = Nanoc::Site.new('.')
      error = assert_raises(RuntimeError) do
        site.compile
      end
      assert_match /^The path returned for the.*does not start with a slash. Please ensure that all routing rules return a path that starts with a slash./, error.message
    end
  end

  def test_load_should_be_idempotent
    # Create site
    Nanoc::CLI.run %w( create_site bar)

    FileUtils.cd('bar') do
      site = Nanoc::Site.new('.')

      compiler = Nanoc::Compiler.new(site)
      def compiler.route_reps
        raise 'oh my gosh it is borken'
      end

      assert site.instance_eval { !@loaded }
      assert_raises(RuntimeError) { compiler.load }
      assert site.instance_eval { !@loaded }
      assert_raises(RuntimeError) { compiler.load }
    end
  end

  def test_compile_should_recompile_all_reps
    Nanoc::CLI.run %w( create_site bar )

    FileUtils.cd('bar') do
      Nanoc::CLI.run %w( compile )

      site = Nanoc::Site.new('.')
      site.compile

      # At this point, even the already compiled items in the previous pass
      # should have their compiled content assigned, so this should work:
      site.items[0].reps[0].compiled_content
    end
  end

  def test_disallow_multiple_snapshots_with_the_same_name
    # Create site
    Nanoc::CLI.run %w( create_site bar )

    FileUtils.cd('bar') do
      # Create routes
      File.open('Rules', 'w') do |io|
        io.write "compile '*' do\n"
        io.write "  snapshot :aaa\n"
        io.write "  snapshot :aaa\n"
        io.write "end\n"
        io.write "\n"
        io.write "route '*' do\n"
        io.write "  '/index.html'\n"
        io.write "end\n"
        io.write "\n"
        io.write "layout '*', :erb\n"
      end

      # Compile
      site = Nanoc::Site.new('.')
      assert_raises Nanoc::Errors::CannotCreateMultipleSnapshotsWithSameName do
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
      site = Nanoc::Site.new('.')
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
      site = Nanoc::Site.new('.')
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
      site = Nanoc::Site.new('.')
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
      site = Nanoc::Site.new('.')
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
      site = Nanoc::Site.new('.')
      site.compile

      # Check
      assert_equal '<h1>B</h1>', File.read('output/index.html')
    end
  end

end
