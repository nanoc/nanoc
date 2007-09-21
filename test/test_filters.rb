require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class FiltersTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_string_eruby
    assert_equal('moo', '<%= "moo" %>'.eruby)
    assert_equal('bar', '<%= @foo %>'.eruby(:assigns => { :foo => 'bar' }))
  end

  def test_string_erubis
    assert_equal('moo', '<%= "moo" %>'.erubis)
    assert_equal('bar', '<%= @foo %>'.erubis(:assigns => { :foo => 'bar' }))
  end

  def test_string_erb
    assert_equal('moo', '<%= "moo" %>'.erb)
    assert_equal('bar', '<%= @foo %>'.erb(:assigns => { :foo => 'bar' }))
  end

  def test_string_haml
    assert_equal("<p>Test</p>\n", '%p Test'.haml)
    assert_equal("<p>bar</p>\n", '%p= foo'.haml(:assigns => { :foo => 'bar' }))
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#haml (Haml not installed?)'
  end

  def test_string_liquid
    assert_equal('<p>bar</p>', '<p>{{foo}}</p>'.liquid(:assigns => { :foo => 'bar' }))
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#liquid (Liquid not installed?)'
  end

  def test_string_markaby
    assert_match(/<h1>Hello<\/h1>/, 'html { body { h1 "Hello" }}'.markaby)
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#markaby (Markaby not installed?)'
  end

  def test_string_markdown
    assert_equal('<p>Hello!</p>', 'Hello!'.markdown)
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#markdown (BlueCloth not installed?)'
  end

  def test_string_rdoc
    assert_match(/We should <em>test<\/em> this/, 'We should _test_ this'.rdoc)
  end

  def test_string_sass
    assert_equal(
      "#main p {\n  color: #00ff00;\n  width: 97%; }\n",
      "#main p\n  :color #00ff00\n  :width 97%".sass
    )
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#sass (Sass not installed?)'
  end

  def test_string_smartypants
    assert_equal('Te&#8217;st', 'Te\'st'.smartypants)
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#smartypants (RubyPants not installed?)'
  end

  def test_string_textile
    assert_equal('<p><em>foo</em> and <strong>bar</strong></p>', '<em>foo</em> and <strong>bar</strong>'.textile)
  rescue SystemExit
    $stderr.print 'WARNING: Unable to test String#textile (RedCloth not installed?)'
  end

end
