require 'helper'

class Nanoc::Filters::ColorizeSyntax::CommonTest < Nanoc::TestCase
  def test_dummy
    if_have 'nokogiri' do
      # Create filter
      filter = ::Nanoc::Filters::ColorizeSyntax.new

      # Get input and expected output
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'
      expected_output = input # because we are using a dummy

      # Run filter
      actual_output = filter.setup_and_run(input, default_colorizer: :dummy)
      assert_equal(expected_output, actual_output)
    end
  end

  def test_with_frozen_input
    if_have 'nokogiri' do
      input = '<pre title="moo"><code class="language-ruby"># comment</code></pre>'.freeze
      input.freeze

      filter = ::Nanoc::Filters::ColorizeSyntax.new
      filter.setup_and_run(input, default_colorizer: :dummy)
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
      expected_output_regex = %r{^<!DOCTYPE html>\s*<html>\s*<head>\s*<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\s*<title>Foo</title>\s*</head>\s*<body>\s*<pre title="moo"><code class="language-ruby"># comment</code></pre>\s*</body>\s*</html>}

      # Run filter
      actual_output = filter.setup_and_run(input, default_colorizer: :dummy, is_fullpage: true)
      assert_match expected_output_regex, actual_output
    end
  end

  def test_full_page_html5
    # Create filter
    filter = ::Nanoc::Filters::ColorizeSyntax.new

    # Get input and expected output
    input = <<EOS
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Foo</title>
</head>
<body>
  <pre title="moo"><code class="language-ruby"># comment</code></pre>
</body>
</html>
EOS
    expected_output_regex = %r{^<!DOCTYPE html>\s*<html>\s*<head>\s*<meta charset="utf-8">\s*<title>Foo</title>\s*</head>\s*<body>\s*<pre title="moo"><code class="language-ruby"># comment</code></pre>\s*</body>\s*</html>}

    # Run filter
    actual_output = filter.setup_and_run(input, syntax: :html5, default_colorizer: :dummy, is_fullpage: true)
    assert_match expected_output_regex, actual_output
  end

  def test_colorize_syntax_with_missing_executables
    if_have 'nokogiri' do
      begin
        original_path = ENV['PATH']
        ENV['PATH'] = './blooblooblah'

        # Create filter
        filter = ::Nanoc::Filters::ColorizeSyntax.new

        # Get input and expected output
        input = '<pre><code class="language-ruby">puts "foo"</code></pre>'

        # Run filter
        %i[albino pygmentize simon_highlight].each do |colorizer|
          begin
            input = '<pre><code class="language-ruby">puts "foo"</code></pre>'
            filter.setup_and_run(
              input,
              colorizers: { ruby: colorizer },
            )
            flunk 'expected colorizer to raise if no executable is available'
          rescue
          end
        end
      ensure
        ENV['PATH'] = original_path
      end
    end
  end
end
