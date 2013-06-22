# encoding: utf-8

class Nanoc::Filters::LessTest < Nanoc::TestCase

  def setup
    super

    @item = Nanoc::Item.new(Nanoc::TextualContent.new('blah', File.absolute_path('content/foo/bar.txt')), {}, '/foo/bar.txt')
  end

  def test_filter
    if_have 'less' do
      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter
      result = filter.setup_and_run('.foo { bar: 1 + 1 }')
      assert_match(/\.foo\s*\{\s*bar:\s*2;?\s*\}/, result)
    end
  end

  def test_filter_with_paths_relative_to_site_directory
    if_have 'less' do
      # Create file to import
      FileUtils.mkdir_p('content/foo/qux')
      File.write('content/foo/qux/imported_file.less', 'p { color: red; }')

      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter
      result = filter.setup_and_run('@import "content/foo/qux/imported_file.less";')
      assert_match(/p\s*\{\s*color:\s*red;?\s*\}/, result)
    end
  end

  def test_filter_with_paths_relative_to_current_file
    if_have 'less' do
      # Create file to import
      FileUtils.mkdir_p('content/foo/qux')
      File.write('content/foo/qux/imported_file.less', 'p { color: red; }')

      # Create item
      File.write('content/foo/bar.txt', 'meh')

      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter
      result = filter.setup_and_run('@import "qux/imported_file.less";')
      assert_match(/p\s*\{\s*color:\s*red;?\s*\}/, result)
    end
  end

  def test_recompile_includes
    if_have 'less' do
      in_site do
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
          io.write "compile '/a.less' do\n"
          io.write "  filter :less\n"
          io.write "  write item.identifier.with_ext('css')\n"
          io.write "end\n"
          io.write "\n"
          io.write "compile '/b.less' do\n"
          io.write "  filter :less\n"
          io.write "end\n"
        end

        # Compile
        compile_site_here

        # Check
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match(/^p\s*\{\s*color:\s*red;?\s*\}/, File.read('output/a.css'))

        # Update included file
        File.write('content/b.less', 'p { color: blue; }')

        # Recompile
        compile_site_here

        # Recheck
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match(/^p\s*\{\s*color:\s*blue;?\s*\}/, File.read('output/a.css'))
      end
    end
  end

  def test_compression
    if_have 'less' do
      # Create filter
      filter = ::Nanoc::Filters::Less.new(:item => @item, :items => [ @item ])

      # Run filter with compress option
      result = filter.setup_and_run('.foo { bar: a; } .bar { foo: b; }', :compress => true)
      assert_match(/^\.foo\{bar:a;\}\n\.bar\{foo:b;\}/, result)
    end
  end

end
