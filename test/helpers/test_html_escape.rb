require 'test/helper'

class Nanoc3::Helpers::HTMLEscapeTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::HTMLEscape

  def test_html_escape
    assert_equal('&lt;',    html_escape('<'))
    assert_equal('&gt;',    html_escape('>'))
    assert_equal('&amp;',   html_escape('&'))
    assert_equal('&quot;',  html_escape('"'))
  end

end
