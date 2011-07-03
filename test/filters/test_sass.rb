# encoding: utf-8

class Nanoc::Filters::SassTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'sass' do
      # Get filter
      filter = create_filter({ :foo => 'bar' })

      # Run filter
      result = filter.run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/, result)
    end
  end

  def test_filter_with_params
    if_have 'sass' do
      # Create filter
      filter = create_filter({ :foo => 'bar' })

      # Check with compact
      result = filter.run(".foo #bar\n  color: #f00", :style => 'compact')
      assert_match(/^\.foo #bar[\s\n]*\{[\s\n]*color:\s*(red|#f00);?[\s\n]*\}/m, result)

      # Check with compressed
      result = filter.run(".foo #bar\n  color: #f00", :style => 'compressed')
      assert_match(/^\.foo #bar[\s\n]*\{[\s\n]*color:\s*(red|#f00);?[\s\n]*\}/m, result)
    end
  end

  def test_filter_error
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Run filter
      raised = false
      begin
        filter.run('$*#&!@($')
      rescue Sass::SyntaxError => e
        assert_match ':1', e.backtrace[0]
        raised = true
      end
      assert raised
    end
  end

  def test_filter_can_import_external_files
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Create sample file
      File.open('moo.sass', 'w') { |io| io.write "body\n  color: red" }

      # Run filter
      filter.run('@import moo')
    end
  end

  def test_filter_can_import_relative_files
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Create sample file
      File.open('moo.sass', 'w') { |io| io.write %Q{@import subdir/relative} }
      FileUtils.mkdir_p("subdir")
      File.open('subdir/relative.sass', 'w') { |io| io.write "body\n  color: red" }

      # Run filter
      filter.run('@import moo')
    end
  end

  def test_filter_will_skip_items_without_filename
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Create sample file
      File.open('moo.sass', 'w') { |io| io.write "body\n  color: red" }

      # Run filter
      filter.run('@import moo')
    end
  end

  def test_css_imports_work
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Run filter
      filter.run('@import moo.css')
    end
  end

  def test_recompile_includes
    if_have 'sass' do
      with_site do |site|
        # Create two Sass files
        Dir['content/*'].each { |i| FileUtils.rm(i) }
        File.open('content/a.sass', 'w') do |io|
          io.write('@import b.sass')
        end
        File.open('content/b.sass', 'w') do |io|
          io.write("p\n  color: red")
        end

        # Update rules
        File.open('Rules', 'w') do |io|
          io.write "compile '*' do\n"
          io.write "  filter :sass\n"
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
        assert_match /^p\s*\{\s*color:\s*red;?\s*\}/,
          File.read('output/a.css')

        # Update included file
        File.open('content/b.sass', 'w') do |io|
          io.write("p\n  color: blue")
        end

        # Recompile
        site = Nanoc::Site.new('.')
        site.compile

        # Recheck
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match /^p\s*\{\s*color:\s*blue;?\s*\}/,
          File.read('output/a.css')
      end
    end
  end

  def test_recompile_includes_with_underscore_without_extension
    if_have 'sass' do
      with_site do |site|
        # Create two Sass files
        Dir['content/*'].each { |i| FileUtils.rm(i) }
        File.open('content/a.sass', 'w') do |io|
          io.write('@import b')
        end
        File.open('content/_b.sass', 'w') do |io|
          io.write("p\n  color: red")
        end

        # Update rules
        File.open('Rules', 'w') do |io|
          io.write "compile '*' do\n"
          io.write "  filter :sass\n"
          io.write "end\n"
          io.write "\n"
          io.write "route '/a/' do\n"
          io.write "  item.identifier.chop + '.css'\n"
          io.write "end\n"
          io.write "\n"
          io.write "route '/_b/' do\n"
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
        assert_match /^p\s*\{\s*color:\s*red;?\s*\}/,
          File.read('output/a.css')

        # Update included file
        File.open('content/_b.sass', 'w') do |io|
          io.write("p\n  color: blue")
        end

        # Recompile
        site = Nanoc::Site.new('.')
        site.compile

        # Recheck
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match /^p\s*\{\s*color:\s*blue;?\s*\}/,
          File.read('output/a.css')
      end
    end
  end

private

  def create_filter(params={})
    FileUtils.mkdir_p('content')
    File.open('content/xyzzy.sass', 'w') { |io| io.write('p\n  color: green')}

    items = [ Nanoc::Item.new(
      'blah',
      { :content_filename => 'content/xyzzy.sass' },
      '/blah/') ]
    params = { :item => items[0], :items => items }.merge(params)
    ::Nanoc::Filters::Sass.new(params)
  end

end
