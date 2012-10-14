# encoding: utf-8

class Nanoc::Filters::ColorizeSyntaxTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

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
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_dummy
    if_have 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = input # because we are using a dummy

      # Run filter
      actual_output = filter.run(input, :default_colorizer => :dummy)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_full_page
    if_have 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = <<EOS
<!DOCTYPE html>
<html>
  <head>
    <title>Foo</title>
  </head>
  <body>
    <pre title="moo"><code class="language-ruby"># comment</code></pre>
  </body>
</html>
EOS
      expected_output = <<EOS
<!DOCTYPE html>
<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
<title>Foo</title>
</head>
<body>
    <pre title="moo"><code class="language-ruby"># comment</code></pre>
  </body>
</html>
EOS

      # Run filter
      actual_output = filter.run(input, :default_colorizer => :dummy, :is_fullpage => true)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_comment
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %[<pre title="moo"><code>#!ruby\n# comment</code></pre>]
      expected_output = CODERAY_PRE + '<pre title="moo"><code class="language-ruby"><span class="comment"># comment</span></code></pre>' + CODERAY_POST

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_coderay_with_comment_and_class
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = %[<pre title="moo"><code class="language-ruby">#!ruby\n# comment</code></pre>]
      expected_output = CODERAY_PRE + %[<pre title="moo"><code class="language-ruby"><span class="doctype">#!ruby</span>\n<span class="comment"># comment</span></code></pre>] + CODERAY_POST

      # Run filter
      actual_output = filter.run(input)
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
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_pygmentize
    if_have 'nokogiri', 'systemu' do
      if `which pygmentize`.strip.empty?
        skip "could not find pygmentize"
      end

      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c1"># comment</span></code></pre>'

      # Run filter
      actual_output = filter.run(input, :colorizers => { :ruby => :pygmentize })
      assert_equal(expected_output, actual_output)
    end
  end

  def test_pygmentsrb
    if_have 'pygments', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment…</code></pre>'
      expected_output = '<pre title="moo"><code class="language-ruby"><span class="c1"># comment…</span></code></pre>'

      # Run filter
      actual_output = filter.run(input, :colorizers => { :ruby => :pygmentsrb })
      assert_equal(expected_output, actual_output)
    end
  end

  def test_simon_highlight
    if_have 'nokogiri', 'systemu' do
      if `which highlight`.strip.empty?
        skip "could not find `highlight`"
      end

      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

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
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Run filter
      assert_raises RuntimeError do
        filter.run('<p>whatever</p>', :syntax => :kasflwafhaweoineurl)
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
      actual_output = filter.run(input, :syntax => :xml)
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
      actual_output = filter.run(input, :syntax => :xhtml)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_default_colorizer
    if `which pygmentize`.strip.empty?
      skip 'no pygmentize found, which is required for this test'
      return
    end

    if_have 'nokogiri', 'systemu' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre><code class="language-ruby">puts "foo"</code></pre>'
      expected_output = '<pre><code class="language-ruby"><span class="nb">puts</span> <span class="s2">"foo"</span></code></pre>'

      # Run filter
      actual_output = filter.run(input, :default_colorizer => :pygmentize)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_missing_executables
    if_have 'nokogiri', 'systemu' do
      begin
        original_path = ENV['PATH']
        ENV['PATH'] = './blooblooblah'

        # Create filter
        filter = ::Nanoc::Filters::ColorizeSyntax.new

        # Get input and expected output
        input = '<pre><code class="language-ruby">puts "foo"</code></pre>'

        # Run filter
        [ :albino, :pygmentize, :simon_highlight ].each do |colorizer|
          begin
            input = '<pre><code class="language-ruby">puts "foo"</code></pre>'
            actual_output = filter.run(
              input,
              :colorizers => { :ruby => colorizer })
            flunk "expected colorizer to raise if no executable is available"
          rescue => e
          end
        end
      ensure
        ENV['PATH'] = original_path
      end
    end
  end

  def test_colorize_syntax_with_non_language_shebang_line
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = <<EOS
before
<pre><code>
#!/usr/bin/env ruby
puts 'hi!'
</code></pre>
after
EOS
      expected_output = <<EOS
before
<pre><code>
#!/usr/bin/env ruby
puts 'hi!'
</code></pre>
after
EOS

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_colorize_syntax_with_non_language_shebang_line_and_language_line
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = <<EOS
before
<pre><code>
#!ruby
#!/usr/bin/env ruby
puts 'hi!'
</code></pre>
after
EOS
      expected_output = <<EOS
before
#{CODERAY_PRE}<pre><code class=\"language-ruby\"><span class=\"doctype\">#!/usr/bin/env ruby</span>
puts <span class=\"string\"><span class=\"delimiter\">'</span><span class=\"content\">hi!</span><span class=\"delimiter\">'</span></span></code></pre>#{CODERAY_POST}
after
EOS

      # Run filter
      actual_output = filter.run(input)
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
      actual_output = filter.run(input, :outside_pre => false)
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
      actual_output = filter.run(input, :outside_pre => true)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_strip
    if_have 'coderay', 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Simple test
      assert_equal "  bar", filter.send(:strip, "\n  bar")

      # Get input and expected output
      input = <<EOS
before
<pre><code class="language-ruby">
  def foo
  end
</code></pre>
after
EOS
      expected_output = <<EOS
before
#{CODERAY_PRE}<pre><code class="language-ruby">  <span class=\"keyword\">def</span> <span class=\"function\">foo</span>
  <span class=\"keyword\">end</span></code></pre>#{CODERAY_POST}
after
EOS

      # Run filter
      actual_output = filter.run(input)
      assert_equal(expected_output, actual_output)
    end
  end

end
