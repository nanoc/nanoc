# encoding: utf-8

class Nanoc::Filters::RelativizePathsTest < Nanoc::TestCase

  def create_filter_and_item_rep_with_path(path)
    @filter = Nanoc::Filters::RelativizePaths.new
    @filter.instance_eval do
      snapshot_store = Nanoc::SnapshotStore::InMemory.new
      item = Nanoc::Item.new('content', {}, '/foo/bar/baz.html')
      @item_rep = Nanoc::ItemRep.new(item, :blah, :snapshot_store => snapshot_store)
      @item_rep.paths = { :last => path }
    end
  end

  def teardown
    super
    @filter = nil
  end

  def test_filter_html_with_double_quotes
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[<a href="/foo">foo</a>]
      expected_content = %[<a href="../..">foo</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_with_single_quotes
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[<a href='/foo'>foo</a>]
      expected_content = %[<a href="../..">foo</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_without_quotes
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[<a href=/foo>foo</a>]
      expected_content = %[<a href="../..">foo</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_with_boilerplate
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content     = <<EOS
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
      expected_match_0 = %r{<a href="\.\./\.\.">foo</a>}
      expected_match_1 = %r{^<!DOCTYPE html>\s*<html>\s*<head>(.|\s)*<title>Hello</title>\s*</head>\s*<body>\s*<a href="../..">foo</a>\s*</body>\s*</html>\s*$}

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_match(expected_match_0, actual_content)
      assert_match(expected_match_1, actual_content)
    end
  end

  def test_filter_html_multiple
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[<a href="/foo">foo</a> <a href="/bar">bar</a>]
      expected_content = %[<a href="../..">foo</a> <a href="../../../bar">bar</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_nested
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[<a href="/"><img src="/bar.png" /></a>]
      expected_content = %[<a href="../../../"><img src="../../../bar.png"></a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_outside_tag
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[stuff href="/foo" more stuff]
      expected_content = %[stuff href="/foo" more stuff]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_root
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[<a href="/">foo</a>]
      expected_content = %[<a href="../../">foo</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_network_path
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[<a href="//example.com/">example.com</a>]
      expected_content = %[<a href="//example.com/">example.com</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_with_anchor
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[<a href="#max-payne">Max Payne</a>]
      expected_content = %[<a href="#max-payne">Max Payne</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_with_url
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[<a href="http://example.com/">Example</a>]
      expected_content = %[<a href="http://example.com/">Example</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_html_with_relative_path
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[<a href="example">Example</a>]
      expected_content = %[<a href="example">Example</a>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end


  def test_filter_html_object_with_relative_path
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[<object data="/example"><param name="movie" content="/example"></object>]
      expected_content = %[<object data="../../example"><param name="movie" content="../../example"></object>]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_implicit
    if_have 'nokogiri' do
      # Create filter with mock item
      @filter = Nanoc::Filters::RelativizePaths.new

      # Test
      assert_raises(RuntimeError) do
        @filter.setup_and_run("moo")
      end
    end
  end

  def test_filter_css_with_double_quotes
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[background: url("/foo/bar/background.png");]
      expected_content = %[background: url("../background.png");]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :css)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_css_with_single_quotes
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[background: url('/foo/bar/background.png');]
      expected_content = %[background: url('../background.png');]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :css)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_css_without_quotes
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[background: url(/foo/bar/background.png);]
      expected_content = %[background: url(../background.png);]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :css)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_css_multiple
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[background: url(/foo/bar/a.png) url(/foo/bar/b.png);]
      expected_content = %[background: url(../a.png) url(../b.png);]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :css)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_css_root
    if_have 'nokogiri' do
      # It is probably a bit weird to have “url(/)” in CSS, but I’ve made a
      # test case for this situation anyway. Can’t hurt…

      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[background: url(/);]
      expected_content = %[background: url(../../);]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :css)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_css_network_path
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/woof/meow/')

      # Set content
      content          = %[background: url(//example.com);]
      expected_content = %[background: url(//example.com);]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :css)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_xml
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content     = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<foo>
  <bar boo="/foo">baz</bar>
</foo>
XML

      expected_content = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<foo>
  <bar boo="../..">baz</bar>
</foo>
XML

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :xml, :select => ['*/@boo'])
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_fragment_xml
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content     = <<-XML
<foo>
  <bar><far href="/foo">baz</far></bar>
</foo>
XML

      expected_content = <<-XML
<foo>
  <bar><far href="../..">baz</far></bar>
</foo>
XML

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :xml, :select => ['far/@href'])
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_xml_with_namespaces
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content     = <<-XML
<foo xmlns="http://example.org">
  <bar><a href="/foo">baz</a></bar>
</foo>
XML

      expected_content = <<-XML
<foo xmlns="http://example.org">
  <bar><a href="../..">baz</a></bar>
</foo>
XML

      # Test
      actual_content = @filter.setup_and_run(content    , {
        :type => :xml, 
        :namespaces => {:ex => 'http://example.org'}, 
        :select => ['ex:a/@href']
      })
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_xhtml
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content     = <<-XML
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

      expected_match = %r{^<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>.*<meta.*charset.*>
    <link rel="stylesheet" href="../../../css" />
    <script src="../../../js"></script>
  </head>
  <body>
    <a href="../..">bar</a>
    <img src="../../../img" />
  </body>
</html>}

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :xhtml)
      assert_match expected_match, actual_content
    end
  end

  def test_filter_fragment_xhtml
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content     = <<-XML
<a href="/foo">bar</a>
<p>
  <img src="/img"/>
</p>
XML

      expected_content = <<-XML
<a href="../..">bar</a>
<p>
  <img src="../../../img" />
</p>
XML

      # Test
      actual_content = @filter.setup_and_run(content    .freeze, :type => :xhtml)
      assert_equal(expected_content, actual_content)
    end
  end

  def test_filter_fragment_xhtml_with_comments
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/baz/')

      # Set content
      content     = %[
<link rel="stylesheet" href="/foo.css" />
<!--[if lt IE 9]>
    <script src="/js/lib/html5shiv.js"></script>
<![endif]-->
]

      expected_content = %[
<link rel="stylesheet" href="../../foo.css" />
<!--[if lt IE 9]>
    <script src="../../js/lib/html5shiv.js"></script>
<![endif]-->
]

      # Test
      actual_content = @filter.setup_and_run(content    .freeze, :type => :xhtml)
      assert_equal(expected_content, actual_content)
    end
  end


  def test_filter_fragment_html_with_comments
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/baz/')

      # Set content
      content     = %[
<!--[if lt IE 9]>
    <script src="/js/lib/html5shiv.js"></script>
<![endif]-->
]

      # Test
      actual_content = @filter.setup_and_run(content    .freeze, :type => :html)
      assert actual_content.include? %[<script src="../../js/lib/html5shiv.js">]
    end
  end

  def test_filter_html_doctype
    if_have 'nokogiri' do
      self.create_filter_and_item_rep_with_path('/foo/bar/baz/')

      # Set content
      content          = %[&lt;!DOCTYPE html>]
      expected_content = %[&lt;!DOCTYPE html&gt;]

      # Test
      actual_content = @filter.setup_and_run(content    , :type => :html)
      assert_equal(expected_content, actual_content)
    end
  end

end
