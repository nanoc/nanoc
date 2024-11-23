# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::HamlTest < Nanoc::TestCase
  def test_filter
    # Create filter
    filter = ::Nanoc::Filters::Haml.new(question: 'Is this the Payne residence?')

    # Run filter (no assigns)
    result = filter.setup_and_run('%html')

    assert_match(/<html>.*<\/html>/, result)

    # Run filter (assigns without @)
    result = filter.setup_and_run('%p= question')

    assert_equal("<p>Is this the Payne residence?</p>\n", result)

    # Run filter (assigns with @)
    result = filter.setup_and_run('%p= @question')

    assert_equal("<p>Is this the Payne residence?</p>\n", result)
  end

  def test_filter_with_params
    # Create filter
    filter = ::Nanoc::Filters::Haml.new(foo: 'bar')

    # Check with HTML5
    result = filter.setup_and_run('%img', format: :html5)

    assert_match(/<img>/, result)

    # Check with XHTML
    result = filter.setup_and_run('%img', format: :xhtml)

    assert_match(/<img\s*\/>/, result)
  end

  def test_filter_error
    # Create filter
    filter = ::Nanoc::Filters::Haml.new(foo: 'bar')

    # Run filter
    raised = false
    begin
      filter.setup_and_run('%p= this isn\'t really ruby so it\'ll break, muahaha')
    rescue SyntaxError, Haml::SyntaxError => e
      e.message =~ /(.+?):\d+: /

      assert_equal '(__TEMPLATE__)', Regexp.last_match[1]
      raised = true
    end

    assert raised
  end

  def test_filter_with_yield
    # Create filter
    filter = ::Nanoc::Filters::Haml.new(content: 'Is this the Payne residence?')

    # Run filter
    result = filter.setup_and_run('%p= yield')

    assert_equal("<p>Is this the Payne residence?</p>\n", result)
  end

  def test_filter_with_yield_without_content
    # Create filter
    filter = ::Nanoc::Filters::Haml.new(location: 'Is this the Payne residence?')

    # Run filter
    assert_raises LocalJumpError do
      filter.setup_and_run('%p= yield')
    end
  end

  def test_filter_with_proper_indentation
    # Create file to include
    File.write('stuff', "<pre>Max Payne\nMona Sax</pre>")

    # Run filter
    filter = ::Nanoc::Filters::Haml.new
    result = filter.setup_and_run("%body\n  ~ File.read('stuff')")

    assert_match(/Max Payne\nMona Sax/, result)
  end

  def test_filter_render
    with_site(legacy: false) do |_site|
      # Prepare
      File.write('lib/helpers.rb', "include Nanoc::Helpers::Rendering\n")
      FileUtils.mkdir_p('layouts/partials')
      File.write('layouts/partials/foobar.haml', <<~HAML)
        .foobar
          %h2 This is a partial rendered from a page

          - if block_given?
            - _erbout << yield
      HAML
      # NOTE: Using `- _erbout << yield` instead of `= yield` above to avoid escaping.
      File.write('content/page.haml', <<~HAML)
        %h1 Example page

        = render("/partials/foobar.haml") do
          %h2 This should work normally
      HAML
      File.write('Rules', <<~RULES)
        compile '/**/*.haml' do
          filter :haml
          write ext: 'html'
        end

        layout '/**/*.haml', :haml
      RULES

      # Compile
      Nanoc::CLI.run(%w[compile])

      # Check
      expected_regex = %r{
        <h1>Example\ page</h1>
        .*
        <div\ class=(['"]?)foobar\1>
        .*
        <h2>This\ is\ a\ partial\ rendered\ from\ a\ page</h2>
        .*
        <h2>This\ should\ work\ normally</h2>
        .*
        </div>
      }xm

      assert_match expected_regex, File.read('output/page.html')
    end
  end
end
