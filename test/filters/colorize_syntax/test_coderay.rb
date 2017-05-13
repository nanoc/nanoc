# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::ColorizeSyntax::CoderayTest < Nanoc::TestCase
  CODERAY_PRE  = '<div class="CodeRay"><div class="code">'
  CODERAY_POST = '</div></div>'

  def test_coderay_simple
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = CODERAY_PRE + '<pre title="moo"><code class="language-ruby"><span class="comment"># comment</span></code></pre>' + CODERAY_POST

      # Run filter
      actual_output = filter.setup_and_run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_comment
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %(<pre title="moo"><code>#!ruby
# comment</code></pre>)
      expected_output = CODERAY_PRE + '<pre title="moo"><code class="language-ruby"><span class="comment"># comment</span></code></pre>' + CODERAY_POST

      # Run filter
      actual_output = filter.setup_and_run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_comment_in_middle
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %(<pre title="moo"><code>def moo ; end
#!ruby
# comment</code></pre>)
      expected_output = "<pre title=\"moo\"><code>def moo ; end\n#!ruby\n# comment</code></pre>"

      # Run filter
      actual_output = filter.setup_and_run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_comment_and_class
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %(<pre title="moo"><code class="language-ruby">#!ruby
# comment</code></pre>)
      expected_output = CODERAY_PRE + %(<pre title="moo"><code class="language-ruby"><span class="doctype">#!ruby</span>
<span class="comment"># comment</span></code></pre>) + CODERAY_POST

      # Run filter
      actual_output = filter.setup_and_run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_more_classes
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="abc language-ruby xyz"># comment</code></pre>'
      expected_output = CODERAY_PRE + '<pre title="moo"><code class="abc language-ruby xyz"><span class="comment"># comment</span></code></pre>' + CODERAY_POST

      # Run filter
      actual_output = filter.setup_and_run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_unknown_syntax
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Run filter
      assert_raises RuntimeError do
        filter.setup_and_run('<p>whatever</p>', syntax: :kasflwafhaweoineurl)
      end
    end
  end

  def test_colorize_syntax_with_xml
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<p>foo<br/>bar</p>'
      expected_output = '<p>foo<br/>bar</p>'

      # Run filter
      actual_output = filter.setup_and_run(input, syntax: :xml)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_xhtml
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<p>foo<br/>bar</p>'
      expected_output = '<p>foo<br />bar</p>'

      # Run filter
      actual_output = filter.setup_and_run(input, syntax: :xhtml)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_non_language_shebang_line
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = <<~EOS
        before
        <pre><code>
        #!/usr/bin/env ruby
        puts 'hi!'
        </code></pre>
        after
EOS
      expected_output = <<~EOS.sub(/\s*\Z/m, '')
        before
        <pre><code>
        #!/usr/bin/env ruby
        puts 'hi!'
        </code></pre>
        after
EOS

      # Run filter
      actual_output = filter.setup_and_run(input).sub(/\s*\Z/m, '')
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_non_language_shebang_line_and_language_line
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = <<~EOS
        before
        <pre><code>
        #!ruby
        #!/usr/bin/env ruby
        puts 'hi!'
        </code></pre>
        after
EOS
      expected_output = <<~EOS.sub(/\s*\Z/m, '')
        before
        #{CODERAY_PRE}<pre><code class=\"language-ruby\"><span class=\"doctype\">#!/usr/bin/env ruby</span>
        puts <span class=\"string\"><span class=\"delimiter\">'</span><span class=\"content\">hi!</span><span class=\"delimiter\">'</span></span></code></pre>#{CODERAY_POST}
        after
EOS

      # Run filter
      actual_output = filter.setup_and_run(input).sub(/\s*\Z/m, '')
      assert_equal(expected_output, actual_output)
    end
  end

  def test_not_outside_pre
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input           = '<code class="language-ruby"># comment</code>'
      expected_output = '<code class="language-ruby"># comment</code>'

      # Run filter
      actual_output = filter.setup_and_run(input, outside_pre: false)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_outside_pre
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input           = '<code class="language-ruby"># comment</code>'
      expected_output = '<code class="language-ruby"><span class="comment"># comment</span></code>'

      # Run filter
      actual_output = filter.setup_and_run(input, outside_pre: true)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_strip
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Simple test
      assert_equal '  bar', filter.send(:strip, "\n  bar")

      # Get input and expected output
      input = <<~EOS
        before
        <pre><code class="language-ruby">
          def foo
          end
        </code></pre>
        after
EOS
      expected_output = <<~EOS.sub(/\s*\Z/m, '')
        before
        #{CODERAY_PRE}<pre><code class="language-ruby">  <span class=\"keyword\">def</span> <span class=\"function\">foo</span>
          <span class=\"keyword\">end</span></code></pre>#{CODERAY_POST}
        after
EOS

      # Run filter
      actual_output = filter.setup_and_run(input).sub(/\s*\Z/m, '')
      assert_equal(expected_output, actual_output)
    end
  end
end
