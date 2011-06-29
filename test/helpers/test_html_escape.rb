# encoding: utf-8

class Nanoc::Helpers::HTMLEscapeTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::HTMLEscape

  def test_html_escape_with_string
    assert_equal('&lt;',    html_escape('<'))
    assert_equal('&gt;',    html_escape('>'))
    assert_equal('&amp;',   html_escape('&'))
    assert_equal('&quot;',  html_escape('"'))
  end

  def test_html_escape_with_block
    _erbout = 'moo'

    html_escape do
      _erbout << '<h1>Looks like a header</h1>'
    end

    assert_equal 'moo&lt;h1&gt;Looks like a header&lt;/h1&gt;', _erbout
  end

  def test_html_escape_without_string_or_block
    assert_raises RuntimeError do
      h
    end
  end

end
