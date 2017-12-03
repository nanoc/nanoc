# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::ColorizeSyntax::PygmentsTest < Nanoc::TestCase
  def test_pygmentsrb
    skip 'pygments.rb does not support Windows' if on_windows?
    if_have 'pygments', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment…</code></pre>'
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c1"># comment…</span></code></pre>'

      # Run filter
      actual_output = filter.setup_and_run(input, colorizers: { ruby: :pygmentsrb })
      assert_equal(expected_output, actual_output)
    end
  end
end
