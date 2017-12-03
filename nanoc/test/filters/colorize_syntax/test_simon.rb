# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::ColorizeSyntax::SimonTest < Nanoc::TestCase
  def test_simon_highlight
    if_have 'nokogiri' do
      skip_unless_have_command 'highlight'

      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %(<pre title="moo"><code class="language-ruby">
# comment
</code></pre>)
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="hl slc"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.setup_and_run(input, default_colorizer: :simon_highlight)
      assert_equal(expected_output, actual_output)
    end
  end
end
