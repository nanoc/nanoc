# encoding: utf-8

class Nanoc::Helpers::CapturingTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::Capturing

  def test_content_for
    require 'erb'

    # Build content to be evaluated
    content = "head <% content_for :sidebar do %>\n" +
              "  <%= 1+2 %>\n" +
              "<% end %> foot"

    # Evaluate content
    @item = Nanoc::Item.new('moo', {}, '/blah/')
    result = ::ERB.new(content).result(binding)

    # Check
    assert_equal '3', content_for(@item, :sidebar).strip
    assert_equal '3', @item[:content_for_sidebar].strip
    assert_match(/^head\s+foot$/, result)
  end

  def test_capture
    require 'erb'

    # Capture
    _erbout = 'foo'
    captured_content = capture do
      _erbout << 'bar'
    end

    # Check
    assert_equal 'foo', _erbout
    assert_equal 'bar', captured_content
  end

  def test_content_for_recursively
    require 'erb'

    content = <<EOS
head
<% content_for :box do %>
  basic
<% end %>
<% content_for :box do %>
  before <%= content_for @item, :box %> after
<% end %>
<%= content_for @item, :box %>
foot
EOS

    @item = Nanoc::Item.new('content', {}, '/')
    result = ::ERB.new(content).result(binding)

    expected = %w( head before basic after foot )
    actual   = result.scan(/[a-z]+/)
    assert_equal expected, actual
  end

end
