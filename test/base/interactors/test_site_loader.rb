# encoding: utf-8

class Nanoc::SiteLoaderTest < Nanoc::TestCase

  def test_load
    in_site do
      File.write('nanoc.yaml',              'fooness: high')
      File.write('content/foo-item.md',     'Item stuff')
      File.write('layouts/foo-layout.haml', 'Layout stuff')
      File.write('lib/blah.rb',             'def foo ; end')

      site = Nanoc::SiteLoader.new.load

      assert_equal [ :filesystem      ], site.data_sources.map  { |ds| ds.class.identifier }
      assert_equal [ 'Item stuff'     ], site.items.map         { |e| e.content.string }
      assert_equal [ 'Layout stuff'   ], site.layouts.map       { |e| e.content.string }
      assert_equal [ 'def foo ; end'  ], site.code_snippets.map { |e| e.data }
      assert_equal 'high', site.config[:fooness]
    end
  end

end
