# encoding: utf-8

class Nanoc::Filters::SassTest < Nanoc::TestCase

  def test_filter
    if_have 'sass' do
      # Get filter
      filter = create_filter({ :foo => 'bar' })

      # Run filter
      result = filter.setup_and_run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/, result)
    end
  end

  def test_filter_with_params
    if_have 'sass' do
      # Create filter
      filter = create_filter({ :foo => 'bar' })

      # Check with compact
      result = filter.setup_and_run(".foo #bar\n  color: #f00", :style => 'compact')
      assert_match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m, result)

      # Check with compressed
      result = filter.setup_and_run(".foo #bar\n  color: #f00", :style => 'compressed')
      assert_match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m, result)
    end
  end

  def test_filter_error
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Run filter
      raised = false
      begin
        filter.setup_and_run('$*#&!@($')
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
      filter.setup_and_run('@import moo')
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
      filter.setup_and_run('@import moo')
    end
  end

  def test_filter_will_skip_items_without_filename
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Create sample file
      File.open('moo.sass', 'w') { |io| io.write "body\n  color: red" }

      # Run filter
      filter.setup_and_run('@import moo')
    end
  end

  def test_css_imports_work
    if_have 'sass' do
      # Create filter
      filter = create_filter

      # Run filter
      filter.setup_and_run('@import moo.css')
    end
  end

  def test_recompile_includes
    if_have 'sass' do
      in_site do
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
          io.write "compile '/a.sass' do\n"
          io.write "  filter :sass\n"
          io.write "  write item.identifier.with_ext('css')\n"
          io.write "end\n"
          io.write "\n"
          io.write "compile '/b.sass' do\n"
          io.write "  filter :sass\n"
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
        File.open('content/b.sass', 'w') do |io|
          io.write("p\n  color: blue")
        end

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

  def test_recompile_includes_with_underscore_without_extension
    if_have 'sass' do
      in_site do
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
          io.write "compile '/a.sass' do\n"
          io.write "  filter :sass\n"
          io.write "  write item.identifier.with_ext('css')\n"
          io.write "end\n"
          io.write "\n"
          io.write "compile '/_b.sass' do\n"
          io.write "  filter :sass\n"
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
        File.open('content/_b.sass', 'w') do |io|
          io.write("p\n  color: blue")
        end

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

private

  def create_filter(params={})
    FileUtils.mkdir_p('content')
    File.open('content/blah.sass', 'w') { |io| io.write('p\n  color: green')}

    item = Nanoc::Item.new(Nanoc::TextualContent.new('blah', File.absolute_path('content/blah.sass')), {}, '/blah.sass')

    items = [ item ]
    params = { :item => items[0], :items => items }.merge(params)
    ::Nanoc::Filters::Sass.new(params)
  end

end
