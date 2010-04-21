# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::SassTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'sass' do
      # Get filter
      filter = ::Nanoc3::Filters::Sass.new({ :foo => 'bar' })

      # Run filter
      result = filter.run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+(red|#f00);?\s*\}/, result)
    end
  end

  def test_filter_with_params
    if_have 'sass' do
      # Create filter
      filter = ::Nanoc3::Filters::Sass.new({ :foo => 'bar' })

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
      filter = ::Nanoc3::Filters::Sass.new({ :foo => 'bar' })

      # Run filter
      raised = false
      begin
        filter.run('$*#&!@($')
      rescue Sass::SyntaxError => e
        assert_match '?', e.backtrace[0]
        raised = true
      end
      assert raised
    end
  end

  def test_filter_can_import_external_files
    if_have 'sass' do
      # Create filter
      filter = ::Nanoc3::Filters::Sass.new(:items => [])

      # Create sample file
      File.open('moo.sass', 'w') { |io| io.write "body\n  color: red" }

      # Run filter
      filter.run('@import moo')
    end
  end

  def test_filter_can_import_relative_files
    if_have 'sass' do
      # Create filter
      filter = ::Nanoc3::Filters::Sass.new(:items => [])

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
      filter = ::Nanoc3::Filters::Sass.new(:items => [ Nanoc3::Item.new('blah', {}, '/blah/') ])

      # Create sample file
      File.open('moo.sass', 'w') { |io| io.write "body\n  color: red" }

      # Run filter
      filter.run('@import moo')
    end
  end
  
  def test_css_imports_work
    if_have 'sass' do
      # Create filter
      filter = ::Nanoc3::Filters::Sass.new(:items => [ Nanoc3::Item.new('blah', {}, '/blah/') ])

      # Run filter
      filter.run('@import moo.css')
    end
  end

end
