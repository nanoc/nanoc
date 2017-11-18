# frozen_string_literal: true

require 'helper'

# TODO: Remove this once Redcarpet 1.x support is dropped
require 'redcarpet'

class Nanoc::Filters::RedcarpetTest < Nanoc::TestCase
  def test_find
    refute Nanoc::Filter.named(:redcarpet).nil?
  end

  def test_filter
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    result = filter.setup_and_run('> Quote')
    assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
  end

  def test_with_extensions
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    if ::Redcarpet::VERSION > '2'
      input           = 'this is ~~good~~ bad'
      output_expected = /this is <del>good<\/del> bad/
      output_actual   = filter.setup_and_run(input, options: { strikethrough: true })
    else
      input           = "The quotation 'marks' sure make this look sarcastic!"
      output_expected = /The quotation &lsquo;marks&rsquo; sure make this look sarcastic!/
      output_actual   = filter.setup_and_run(input, options: [:smart])
    end
    assert_match(output_expected, output_actual)
  end

  def test_html_by_default
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    input           = "![Alt](/path/to/img 'Title')"
    output_expected = %r{<img src="/path/to/img" alt="Alt" title="Title">}
    output_actual   = filter.setup_and_run(input)
    assert_match(output_expected, output_actual)
  end

  def test_xhtml_if_requested
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    input           = "![Alt](/path/to/img 'Title')"
    output_expected = %r{<img src="/path/to/img" alt="Alt" title="Title"/>}
    output_actual =
      if ::Redcarpet::VERSION > '2'
        filter.setup_and_run(input, renderer_options: { xhtml: true })
      else
        filter.setup_and_run(input, options: [:xhtml])
      end
    assert_match(output_expected, output_actual)
  end

  def test_html_toc
    unless ::Redcarpet::VERSION > '2'
      skip 'Requires Redcarpet >= 2'
    end

    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    input = "# Heading 1\n## Heading 2\n"
    output_actual = filter.run(input, renderer: Redcarpet::Render::HTML_TOC)

    # Test
    output_expected = %r{<ul>\n<li>\n<a href=\"#heading-1\">Heading 1</a>\n<ul>\n<li>\n<a href=\"#heading-2\">Heading 2</a>\n</li>\n</ul>\n</li>\n</ul>}
    assert_match(output_expected, output_actual)
  end

  def test_toc_if_requested
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    input = "A Title\n======"
    if ::Redcarpet::VERSION > '2'
      output_expected = %r{<ul>\n<li>\n<a href="#a-title">A Title</a>\n</li>\n</ul>\n<h1 id="a-title">A Title</h1>\n}
      output_actual   = filter.setup_and_run(input, with_toc: true)
    else
      output_expected = %r{<h1>A Title</h1>\n}
      output_actual   = filter.setup_and_run(input)
    end

    # Test
    assert_match(output_expected, output_actual)
  end
end
