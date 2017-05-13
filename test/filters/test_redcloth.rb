# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::RedClothTest < Nanoc::TestCase
  def test_filter
    if_have 'redcloth' do
      # Get filter
      filter = ::Nanoc::Filters::RedCloth.new

      # Run filter
      result = filter.setup_and_run('h1. Foo')
      assert_equal('<h1>Foo</h1>', result)
    end
  end

  def test_filter_with_options
    if_have 'redcloth' do
      # Get filter
      filter = ::Nanoc::Filters::RedCloth.new

      # Run filter without options
      result = filter.setup_and_run('I am a member of SPECTRE.')
      assert_equal('<p>I am a member of <span class="caps">SPECTRE</span>.</p>', result)

      # Run filter with options
      result = filter.setup_and_run('I am a member of SPECTRE.', no_span_caps: true)
      assert_equal('<p>I am a member of SPECTRE.</p>', result)
    end
  end
end
