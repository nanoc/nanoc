# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::ColorizeSyntax::PygmentizeTest < Nanoc::TestCase
  def test_pygmentize
    if_have 'nokogiri' do
      skip_unless_have_command 'pygmentize'

      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c1"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.setup_and_run(input, colorizers: { ruby: :pygmentize })
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_default_colorizer
    skip_unless_have_command 'pygmentize'

    if_have 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre><code class="language-ruby">puts "foo"</code></pre>'
      expected_output = '<pre><code class="language-ruby"><span class="nb">puts</span> <span class="s2">"foo"</span></code></pre>'

      # Run filter
      actual_output = filter.setup_and_run(input, default_colorizer: :pygmentize)
      assert_equal(expected_output, actual_output)
    end
  end
end
