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
      @_item_rep = mock
      @_item_rep.expects(:assigns).returns({})

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
                " <p><%%= @item.title %></p>\n" +
                "<% end %>\n"

      # Mock item and rep
      item = mock
      item.expects(:title).returns('Bar...')
      item.expects(:identifier).returns('/blah/')
      @_item_rep = mock
      @_item_rep.expects(:name).returns('default')
      @_item_rep.expects(:assigns).returns({
        :_item      => item,
        :_item_rep  => @_item_rep,
        :item       => item
      })

      # Evaluate content
      result = ::ERB.new(content).result(binding)

      # Check
      assert_match('<p>Foo...</p>', result)
      assert_match('<p>Bar...</p>', result)
    end
  end

end
