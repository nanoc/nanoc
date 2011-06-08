# encoding: utf-8

class Nanoc3::Filters::ColorizeSyntaxTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_coderay_simple
    if_have 'coderay', 'nokogiri' do
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

  def test_coderay_with_comment
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %[<pre title="moo"><code>#!ruby\n# comment</code></pre>]
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_comment_and_class
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %[<pre title="moo"><code class="language-ruby">#!ruby\n# comment</code></pre>]
      expected_output = %[<pre title="moo"><code class="language-ruby"><span class="dt">#!ruby</span>\n<span class="c"># comment</span></code></pre>]

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_more_classes
    if_have 'coderay', 'nokogiri' do
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
    if_have 'nokogiri' do
      if `which pygmentize`.strip.empty?
        skip "could not find pygmentize"
      end

      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c1"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.run(input, :colorizers => { :ruby => :pygmentize })
      assert_equal(expected_output, actual_output)
    end
  end

  def test_simon_highlight
    if_have 'nokogiri' do
      if `which highlight`.strip.empty?
        skip "could not find `highlight`"
      end

      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %Q[<pre title="moo"><code class="language-ruby">\n# comment\n</code></pre>]
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="hl slc"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.run(input, :default_colorizer => :simon_highlight)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_unknown_syntax
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Run filter
      assert_raises RuntimeError do
        filter.run('<p>whatever</p>', :syntax => :kasflwafhaweoineurl)
      end
    end
  end

  def test_colorize_syntax_with_xml
    if_have 'coderay', 'nokogiri' do
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

  def test_colorize_syntax_with_xhtml
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc3::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<p>foo<br/>bar</p>'
      expected_output = '<p>foo<br />bar</p>'

      # Run filter
      actual_output = filter.run(input, :syntax => :xhtml)
      assert_equal(expected_output, actual_output)
    end
  end

end
