# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::LessTest < Nanoc3::StubSiteConfigTestCase

  def test_filter
    if_have 'less' do
      # Create item
      @item = Nanoc3::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc3::Filters::Less.new(:item => @item)

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
      @item = Nanoc3::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc3::Filters::Less.new(:item => @item)

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
      @item = Nanoc3::Item.new("blah", { :content_filename => 'content/foo/bar.txt' }, '/foo/bar/')

      # Create filter
      filter = ::Nanoc3::Filters::Less.new(:item => @item)

      # Run filter
      result = filter.run('@import "bar/imported_file.less";')
      assert_match /p\s*\{\s*color:\s*red;?\s*\}/, result
    end
  end

end
