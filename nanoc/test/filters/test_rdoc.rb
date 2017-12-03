# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::RDocTest < Nanoc::TestCase
  def test_filter
    # Get filter
    filter = ::Nanoc::Filters::RDoc.new

    # Run filter
    result = filter.setup_and_run('= Foo')
    assert_match(%r{\A\s*<h1( id="label-Foo")?>Foo(<span>.*</span>)?</h1>\s*\Z}, result)
  end
end
