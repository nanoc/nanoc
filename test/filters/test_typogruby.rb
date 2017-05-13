# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::TypogrubyTest < Nanoc::TestCase
  def test_filter
    if_have 'typogruby' do
      # Get filter
      filter = ::Nanoc::Filters::Typogruby.new

      # Run filter
      a = '"Typogruby makes HTML look smarter &amp; better, don\'t you think?"'
      b = '<span class="dquo">&#8220;</span>Typogruby makes <span class="caps">HTML</span> look smarter <span class="amp">&amp;</span> better, don&#8217;t you&nbsp;think?&#8221;'
      result = filter.setup_and_run(a)
      assert_equal(b, result)
    end
  end
end
