# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::CoffeeScriptTest < Nanoc::TestCase
  def test_filter
    skip_v8_on_ruby24

    if_have 'coffee-script' do
      # Create filter
      filter = ::Nanoc::Filters::CoffeeScript.new

      # Run filter (no assigns)
      result = filter.setup_and_run('alert 42')
      assert_equal('(function() { alert(42); }).call(this); ', result.gsub(/\s+/, ' '))
    end
  end
end
