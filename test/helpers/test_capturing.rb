require 'test/helper'

class Nanoc::Helpers::CapturingTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Capturing

  def test_content_for
    # Build content to be evaluated
    content = "head <% content_for :sidebar do %>\n" +
              "  <%= 1+2 %>\n" +
              "<% end %> foot"

    # Evaluate content
    @page = {}
    result = ::ERB.new(content).result(binding)

    # Check
    assert(@page[:content_for_sidebar].strip == '3')
    assert_match(/^head\s+foot$/, result)
  end

end
