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
    return unless test_require 'haml'
    assert_equal("<p>Test</p>\n", '%p Test'.haml)
    assert_equal("<p>bar</p>\n", '%p= foo'.haml(:assigns => { :foo => 'bar' }))
  end

  def test_string_liquid
    return unless test_require 'liquid'
    assert_equal('<p>bar</p>', '<p>{{foo}}</p>'.liquid(:assigns => { :foo => 'bar' }))
  end

  def test_string_markaby
    return unless test_require 'markaby'
    assert_match(/<h1>Hello<\/h1>/, 'html { body { h1 "Hello" }}'.markaby)
  end

  def test_string_markdown
    return unless test_require 'bluecloth'
    assert_equal('<p>Hello!</p>', 'Hello!'.markdown)
  end

  def test_string_rdoc
    assert_match(/We should <em>test<\/em> this/, 'We should _test_ this'.rdoc)
  end

  def test_string_sass
    return unless test_require 'haml'
    assert_equal(
      "#main p {\n  color: #00ff00;\n  width: 97%; }\n",
      "#main p\n  :color #00ff00\n  :width 97%".sass
    )
  end

  def test_string_smartypants
    return unless test_require 'rubypants'
    assert_equal('Te&#8217;st', 'Te\'st'.smartypants)
  end

  def test_string_textile
    return unless test_require 'redcloth'
    assert_equal('<p><em>foo</em> and <strong>bar</strong></p>', '<em>foo</em> and <strong>bar</strong>'.textile)
  end

end
