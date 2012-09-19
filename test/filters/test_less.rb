# encoding: utf-8

class Nanoc::Filters::LessTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'less' do
      # Create item
      @item = Nanoc::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter
      result = filter.run('.foo { bar: 1 + 1 }')
      assert_match /\.foo\s*\{\s*bar:\s*2;?\s*\}/, result
    end
  end

  def test_filter_with_paths_relative_to_site_directory
    if_have 'less' do
      # Create file to import
      FileUtils.mkdir_p('content/foo/bar')
      File.open('content/foo/bar/imported_file.less', 'w') { |io| io.write('p { color: red; }') }

      # Create item
      @item = Nanoc::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter
      result = filter.run('@import "content/foo/bar/imported_file.less";')
      assert_match /p\s*\{\s*color:\s*red;?\s*\}/, result
    end
  end

  def test_filter_with_paths_relative_to_current_file
    if_have 'less' do
      # Create file to import
      FileUtils.mkdir_p('content/foo/bar')
      File.open('content/foo/bar/imported_file.less', 'w') { |io| io.write('p { color: red; }') }

      # Create item
      File.open('content/foo/bar.txt', 'w') { |io| io.write('meh') }
      @item = Nanoc::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter
      result = filter.run('@import "bar/imported_file.less";')
      assert_match /p\s*\{\s*color:\s*red;?\s*\}/, result
    end
  end

  def test_recompile_includes
    if_have 'less' do
      with_site do |site|
        # Create two less files
        Dir['content/*'].each { |i| FileUtils.rm(i) }
        File.open('content/a.less', 'w') do |io|
          io.write('@import "b.less";')
        end
        File.open('content/b.less', 'w') do |io|
          io.write("p { color: red; }")
        end

        # Update rules
        File.open('Rules', 'w') do |io|
          io.write "compile '*' do\n"
          io.write "  filter :less\n"
          io.write "end\n"
          io.write "\n"
          io.write "route '/a/' do\n"
          io.write "  item.identifier.chop + '.css'\n"
          io.write "end\n"
          io.write "\n"
          io.write "route '/b/' do\n"
          io.write "  nil\n"
          io.write "end\n"
        end

        # Compile
        site = Nanoc::Site.new('.')
        site.compile

        # Check
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match /^p\s*\{\s*color:\s*red;?\s*\}/, File.read('output/a.css')

        # Update included file
        File.open('content/b.less', 'w') do |io|
          io.write("p { color: blue; }")
        end

        # Recompile
        site = Nanoc::Site.new('.')
        site.compile

        # Recheck
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match /^p\s*\{\s*color:\s*blue;?\s*\}/, File.read('output/a.css')
      end
    end
  end

  def test_compression
    if_have 'less' do
      # Create item
      @item = Nanoc::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter with compress option
      result = filter.run('.foo { bar: a; } .bar { foo: b; }', :compress => true)
      assert_match /^\.foo{bar:a;}\n\.bar{foo:b;}/, result
    end
  end

end
