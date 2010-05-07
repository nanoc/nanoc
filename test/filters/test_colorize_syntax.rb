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

  def test_simon_highlight
    if `which highlight`.strip.empty?
      skip "could not find `highlight`"
    end

    # Create filter
    filter = ::Nanoc3::Filters::ColorizeSyntax.new

    # Get input and expected output
    input = %Q[<pre title="moo"><code class="language-ruby">\n# comment\n</code></pre>]
    expected_output = '<pre title="moo"><code class="language-ruby"><span class="slc"># comment</span></code></pre>'

    # Run filter
    actual_output = filter.run(input, :default_colorizer => :simon_highlight)
    assert_equal(expected_output, actual_output)
  end

  def test_colorize_syntax_with_unknown_syntax
    if_have 'coderay' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Run filter
      assert_raises RuntimeError do
        filter.run('<p>whatever</p>', :syntax => :kasflwafhaweoineurl)
      end
    end
  end

  def test_colorize_syntax_with_xml
    if_have 'coderay' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<p>foo<br/>bar</p>'
      expected_output = '<p>foo<br/>bar</p>'

      # Run filter
      actual_output = filter.run(input, :syntax => :xml)
      assert_equal(expected_output, actual_output)
    end
  end

end
