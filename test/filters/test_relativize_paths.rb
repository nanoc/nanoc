require 'helper'

class Nanoc::Filters::RelativizePathsTest < Nanoc::TestCase
  def test_filter_html_with_double_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(<a href="/foo">foo</a>)
    expected_content = %(<a href="../..">foo</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_single_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(<a href='/foo'>foo</a>)
    expected_content = %(<a href="../..">foo</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_without_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(<a href=/foo>foo</a>)
    expected_content = %(<a href="../..">foo</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_boilerplate
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content = <<EOS
<!DOCTYPE html>
<html>
  <head>
    <title>Hello</title>
  </head>
  <body>
    <a href=/foo>foo</a>
  </body>
</html>
EOS
    expected0 = %r{<a href="\.\./\.\.">foo</a>}
    expected1 = %r{\A\s*<!DOCTYPE html\s*>\s*<html>\s*<head>(.|\s)*<title>Hello</title>\s*</head>\s*<body>\s*<a href="../..">foo</a>\s*</body>\s*</html>\s*\Z}m

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_match(expected0, actual_content)
    assert_match(expected1, actual_content)
  end

  def test_filter_html5_with_boilerplate
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content = <<EOS
<!DOCTYPE html>
<html>
  <head>
    <title>Hello</title>
  </head>
  <body>
    <a href=/foo>foo</a>
  </body>
</html>
EOS
    expected0 = %r{<a href="\.\./\.\.">foo</a>}
    expected1 = %r{\A\s*<!DOCTYPE html\s*>\s*<html>\s*<head>\s*<title>Hello</title>\s*</head>\s*<body>\s*<a href="../..">foo</a>\s*</body>\s*</html>\s*\Z}m

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html5)
    assert_match(expected0, actual_content)
    assert_match(expected1, actual_content)
  end

  def test_filter_html_multiple
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(<a href="/foo">foo</a> <a href="/bar">bar</a>)
    expected_content = %(<a href="../..">foo</a> <a href="../../../bar">bar</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_nested
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(<a href="/"><img src="/bar.png" /></a>)
    expected_content = %(<a href="../../../"><img src="../../../bar.png"></a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_outside_tag
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(stuff href="/foo" more stuff)
    expected_content = %(stuff href="/foo" more stuff)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_root
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %(<a href="/">foo</a>)
    expected_content = %(<a href="../../">foo</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_network_path
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %(<a href="//example.com/">example.com</a>)
    expected_content = %(<a href="//example.com/">example.com</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_anchor
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %(<a href="#max-payne">Max Payne</a>)
    expected_content = %(<a href="#max-payne">Max Payne</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_url
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %(<a href="http://example.com/">Example</a>)
    expected_content = %(<a href="http://example.com/">Example</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_relative_path
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %(<a href="example">Example</a>)
    expected_content = %(<a href="example">Example</a>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_object_with_relative_path
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    raw_content    = %(<object data="/example"><param name="movie" content="/example"></object>)
    actual_content = filter.setup_and_run(raw_content, type: :html)

    assert_match(/<object data="..\/..\/example">/, actual_content)
    assert_match(/<param (name="movie" )?content="..\/..\/example"/, actual_content)
  end

  def test_filter_form
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(<form action="/example"></form>)
    expected_content = %(<form action="../../../example"></form>)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_implicit
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Test
    assert_raises(RuntimeError) do
      filter.setup_and_run('moo')
    end
  end

  def test_filter_css_with_double_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %[background: url("/foo/bar/background.png");]
    expected_content = %[background: url("../background.png");]

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_with_single_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %[background: url('/foo/bar/background.png');]
    expected_content = %[background: url('../background.png');]

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_without_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/background.png);]
    expected_content = %[background: url(../background.png);]

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_multiple
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/a.png) url(/foo/bar/b.png);]
    expected_content = %[background: url(../a.png) url(../b.png);]

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_root
    # It is probably a bit weird to have “url(/)” in CSS, but I’ve made a
    # test case for this situation anyway. Can’t hurt…

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %[background: url(/);]
    expected_content = %[background: url(../../);]

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_network_path
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/woof/meow/']
    end

    # Set content
    raw_content      = %[background: url(//example.com);]
    expected_content = %[background: url(//example.com);]

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_xml
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/bar/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/bar/baz/']
      end

      # Set content
      expected = /<bar boo="\.\.\/\.\.">baz<\/bar>/
      raw_content = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<foo>
  <bar boo="/foo">baz</bar>
</foo>
XML

      actual_content = filter.setup_and_run(raw_content, type: :xml, select: ['*/@boo'])

      assert_match(expected, actual_content)
    end
  end

  def test_filter_fragment_xml
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/bar/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/bar/baz/']
      end

      # Set content
      raw_content = <<-XML
<foo>
  <bar><far href="/foo">baz</far></bar>
</foo>
XML

      actual_content = filter.setup_and_run(raw_content, type: :xml, select: ['far/@href'])

      assert_match(/<foo>/, actual_content)
      assert_match(/<bar><far href="..\/..">baz<\/far><\/bar>/, actual_content)
    end
  end

  def test_filter_xml_with_namespaces
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/bar/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/bar/baz/']
      end

      # Set content
      raw_content = <<-XML
<foo xmlns="http://example.org">
  <bar><a href="/foo">baz</a></bar>
</foo>
XML

      options = {
        type: :xml,
        namespaces: { ex: 'http://example.org' },
        select: ['ex:a/@href'],
      }
      actual_content = filter.setup_and_run(raw_content, options)

      assert_match(/<foo xmlns="http:\/\/example.org">/,    actual_content)
      assert_match(/<bar><a href="..\/..">baz<\/a><\/bar>/, actual_content)
    end
  end

  def test_filter_xhtml
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/bar/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/bar/baz/']
      end

      # Set content
      raw_content = <<-XML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <link rel="stylesheet" href="/css"/>
    <script src="/js"></script>
  </head>
  <body>
    <a href="/foo">bar</a>
    <img src="/img"/>
  </body>
</html>
XML

      actual_content = filter.setup_and_run(raw_content, type: :xhtml)

      assert_match(/<link[^>]*href="..\/..\/..\/css"[^>]*\/>/, actual_content)
      assert_match(/<script src="..\/..\/..\/js">/,            actual_content)
      assert_match(/<img src="..\/..\/..\/img"[^>]*\/>/,       actual_content)
      assert_match(/<a href="..\/..">bar<\/a>/,                actual_content)
    end
  end

  def test_filter_fragment_xhtml
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/bar/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/bar/baz/']
      end

      # Set content
      raw_content = <<-XML
<a href="/foo">bar</a>
<p>
  <img src="/img"/>
</p>
XML

      expected_content =
        %r{\A\s*<a href="../..">bar</a>\s*<p>\s*<img src="../../../img" />\s*</p>\s*\Z}m

      # Test
      actual_content = filter.setup_and_run(raw_content.freeze, type: :xhtml)
      assert_match(expected_content, actual_content)
    end
  end

  def test_filter_fragment_xhtml_with_comments
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/baz/']
      end

      # Set content
      raw_content = %(
<link rel="stylesheet" href="/foo.css" />
<!--[if lt IE 9]>
    <script src="/js/lib/html5shiv.js"></script>
<![endif]-->

)

      actual_content = filter.setup_and_run(raw_content.freeze, type: :xhtml)

      assert_match(/<link (rel="stylesheet" )?href="..\/..\/foo.css" /,      actual_content)
      assert_match(/<script src="..\/..\/js\/lib\/html5shiv.js"><\/script>/, actual_content)
    end
  end

  def test_filter_fragment_html_with_comments
    if_have 'nokogiri' do
      # Create filter with mock item
      filter = Nanoc::Filters::RelativizePaths.new

      # Mock item
      filter.instance_eval do
        @item_rep = Nanoc::Int::ItemRep.new(
          Nanoc::Int::Item.new(
            'content',
            {},
            '/foo/baz/',
          ),
          :blah,
        )
        @item_rep.paths[:last] = ['/foo/baz/']
      end

      # Set content
      raw_content = %(
<!--[if lt IE 9]>
    <script src="/js/lib/html5shiv.js"></script>
<![endif]-->

)

      # Test
      actual_content = filter.setup_and_run(raw_content.freeze, type: :html)
      assert actual_content.include? %(<script src="../../js/lib/html5shiv.js">)
    end
  end

  def test_filter_html_doctype
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc::Int::ItemRep.new(
        Nanoc::Int::Item.new(
          'content',
          {},
          '/foo/bar/baz/',
        ),
        :blah,
      )
      @item_rep.paths[:last] = ['/foo/bar/baz/']
    end

    # Set content
    raw_content      = %(&lt;!DOCTYPE html>)
    expected_content = %(&lt;!DOCTYPE html&gt;)

    # Test
    actual_content = filter.setup_and_run(raw_content, type: :html)
    assert_equal(expected_content, actual_content)
  end
end
