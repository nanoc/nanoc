# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::ColorizeSyntaxTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_coderay_simple
    if_have 'coderay' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_more_classes
    if_have 'coderay' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="abc language-ruby xyz"># comment</code></pre>'
      expected_output = '<pre title="moo"><code class="abc language-ruby xyz"><span class="c"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_pygmentize
    if `which pygmentize`.strip.empty?
      skip "could not find pygmentize"
    end

    # Create filter
    filter = ::Nanoc3::Filters::ColorizeSyntax.new

    # Get input and expected output
    input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
    expected_output = %r{^<pre title="moo"><code class="language-ruby"><span class="c1"># comment</span>\n?</code></pre>$}

    # Run filter
    actual_output = filter.run(input, :colorizers => { :ruby => :pygmentize })
    assert_match(expected_output, actual_output)
  end

  def test_colorize_syntax_with_missing_executables
    if_have 'nokogiri' do
      begin
        original_path = ENV['PATH']
        ENV['PATH'] = './blooblooblah'

        # Create filter
        filter = ::Nanoc3::Filters::ColorizeSyntax.new

        # Get input and expected output
        input = '<pre><code class="language-ruby">puts "foo"</code></pre>'

        # Run filter
        begin
          input = '<pre><code class="language-ruby">puts "foo"</code></pre>'
          actual_output = filter.run(
            input,
            :colorizers => { :ruby => :pygmentize })
          flunk "expected colorizer to raise if no executable is available"
        rescue => e
        end
      ensure
        ENV['PATH'] = original_path
      end
    end
  end

end
