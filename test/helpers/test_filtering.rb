require 'helper'

class Nanoc::Helpers::FilteringTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Filtering

  def test_filter
    if_have 'rubypants' do
      # Build content to be evaluated
      content = "<p>Foo...</p>\n" +
                "<% filter :rubypants do %>\n" +
                " <p>Bar...</p>\n" +
                "<% end %>\n"

      # Mock page and site
      page = mock
      site = mock
      page.expects(:site).returns(site)
      @_obj_rep = mock
      @_obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
      @_obj_rep.expects(:page).returns(page)

      # Evaluate content
      result = ::ERB.new(content).result(binding)

      # Check
      assert_match('<p>Foo...</p>',     result)
      assert_match('<p>Bar&#8230;</p>', result)
    end
  end

end
