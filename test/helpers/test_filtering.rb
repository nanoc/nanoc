# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::FilteringTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Filtering

  def test_filter_simple
    if_have 'rubypants' do
      # Build content to be evaluated
      content = "<p>Foo...</p>\n" +
                "<% filter :rubypants do %>\n" +
                " <p>Bar...</p>\n" +
                "<% end %>\n"

      # Mock item and rep
      @item_rep = mock
      @item_rep.expects(:assigns).returns({})

      # Evaluate content
      result = ::ERB.new(content).result(binding)

      # Check
      assert_match('<p>Foo...</p>',     result)
      assert_match('<p>Bar&#8230;</p>', result)
    end
  end

  def test_filter_with_assigns
    if_have 'rubypants' do
      # Build content to be evaluated
      content = "<p>Foo...</p>\n" +
                "<% filter :erb do %>\n" +
                " <p><%%= @item[:title] %></p>\n" +
                "<% end %>\n"

      # Mock item and rep
      @item = mock
      @item.expects(:[]).with(:title).returns('Bar...')
      @item.expects(:identifier).returns('/blah/')
      @item_rep = mock
      @item_rep.expects(:name).returns('default')
      @item_rep.expects(:assigns).returns({
        :item     => @item,
        :item_rep => @item_rep
      })

      # Evaluate content
      result = ::ERB.new(content).result(binding)

      # Check
      assert_match('<p>Foo...</p>', result)
      assert_match('<p>Bar...</p>', result)
    end
  end

  def test_filter_with_unknown_filter_name
    # Build content to be evaluated
    content = "<p>Foo...</p>\n" +
              "<% filter :askjdflkawgjlkwaheflnvz do %>\n" +
              " <p>Blah blah blah.</p>\n" +
              "<% end %>\n"

    # Evaluate content
    error = assert_raises(Nanoc3::Errors::UnknownFilter) do
      ::ERB.new(content).result(binding)
    end
  end

end
