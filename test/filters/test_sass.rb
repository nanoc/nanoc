# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::SassTest < Nanoc::TestCase
  def setup
    super

    if_have 'sass' do
      unless ::Sass.load_paths.include?('.')
        ::Sass.load_paths << '.'
      end
    end
  end

  def test_filter
    if_have 'sass' do
      # Get filter
      filter = create_filter(foo: 'bar')

      # Run filter
      result = filter.setup_and_run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/, result)
    end
  end

  def test_filter_with_params
    if_have 'sass' do
      # Create filter
      filter = create_filter(foo: 'bar')

      # Check with compact
      result = filter.setup_and_run(".foo #bar\n  color: #f00", style: 'compact')
      assert_match(/^\.foo #bar[\s]*\{[\s]*color:\s*(red|#f00);?[\s]*\}/m, result)

      # Check with compressed
      result = filter.setup_and_run(".foo #bar\n  color: #f00", style: 'compressed')
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
      File.open('moo.sass', 'w') { |io| io.write %(@import subdir/relative) }
      FileUtils.mkdir_p('subdir')
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
        site = Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile

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
        site = Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile

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
        site = Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile

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
        site = Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile

        # Recheck
        assert Dir['output/*'].size == 1
        assert File.file?('output/a.css')
        refute File.file?('output/b.css')
        assert_match(/^p\s*\{\s*color:\s*blue;?\s*\}/, File.read('output/a.css'))
      end
    end
  end

  def test_recompile_includes_with_relative_path
    if_have 'sass', 'compass' do
      with_site do |site|
        # Write compass config
        FileUtils.mkdir_p('compass')
        File.open('compass/config.rb', 'w') do |io|
          io << "project_path = \".\"\n"
          io << "sass_path = \"content/style\"\n"
        end

        # Create two Sass files
        Dir['content/*'].each { |i| FileUtils.rm(i) }
        FileUtils.mkdir_p('content/style/super')
        FileUtils.mkdir_p('content/style/sub')
        File.open('content/style/super/main.sass', 'w') do |io|
          io.write('@import sub/include.sass')
        end
        File.open('content/style/sub/include.sass', 'w') do |io|
          io.write("p\n  color: red")
        end

        # Update rules
        File.open('Rules', 'w') do |io|
          io.write "require 'compass'\n"
          io.write "Compass.add_project_configuration 'compass/config.rb'\n"
          io.write "\n"
          io.write "compile '*' do\n"
          io.write "  filter :sass, Compass.sass_engine_options\n"
          io.write "end\n"
          io.write "\n"
          io.write "route '/style/super/main/' do\n"
          io.write "  item.identifier.chop + '.css'\n"
          io.write "end\n"
          io.write "\n"
          io.write "route '/style/sub/include/' do\n"
          io.write "  nil\n"
          io.write "end\n"
        end

        # Compile
        site = Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile

        # Check
        output_files = Dir['output/**/*'].select { |f| File.file?(f) }
        assert_equal ['output/style/super/main.css'], output_files
        assert_match(/^p\s*\{\s*color:\s*red;?\s*\}/, File.read('output/style/super/main.css'))

        # Update included file
        File.open('content/style/sub/include.sass', 'w') do |io|
          io.write("p\n  color: blue")
        end

        # Recompile
        site = Nanoc::Int::SiteLoader.new.new_from_cwd
        site.compile

        # Recheck
        output_files = Dir['output/**/*'].select { |f| File.file?(f) }
        assert_equal ['output/style/super/main.css'], output_files
        assert_match(/^p\s*\{\s*color:\s*blue;?\s*\}/, File.read('output/style/super/main.css'))
      end
    end
  end

  def test_sass_without_filter
    if_have 'sass' do
      File.open('_morestuff.sass', 'w') do |io|
        io.write("p\n  color: blue")
      end

      options = { filename: File.join(Dir.getwd, 'test.sass') }
      ::Sass::Engine.new('@import "morestuff"', options).render
    end
  end

  private

  def create_filter(params = {})
    FileUtils.mkdir_p('content')
    File.open('content/xyzzy.sass', 'w') { |io| io.write('p\n  color: green') }

    items = [
      Nanoc::ItemWithRepsView.new(
        Nanoc::Int::Item.new(
          'blah',
          { content_filename: 'content/xyzzy.sass' },
          '/blah/',
        ),
        nil,
      ),
    ]
    params = { item: items[0], items: items }.merge(params)
    ::Nanoc::Filters::Sass.new(params)
  end
end
