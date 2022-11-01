# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::RedcarpetTest < Nanoc::TestCase
  def setup
    super
    skip_unless_have 'redcarpet'
  end

  def test_find
    refute_nil Nanoc::Filter.named(:redcarpet)
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
    input           = 'this is ~~good~~ bad'
    output_expected = /this is <del>good<\/del> bad/
    output_actual   = filter.setup_and_run(input, options: { strikethrough: true })

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
    output_actual   = filter.setup_and_run(input, renderer_options: { xhtml: true })

    assert_match(output_expected, output_actual)
  end

  def test_html_toc
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    input = "# Heading 1\n## Heading 2\n"
    output_actual = filter.run(input, renderer: Redcarpet::Render::HTML_TOC)

    # Test
    output_expected = %r{<ul>\n<li>\n<a href="#heading-1">Heading 1</a>\n<ul>\n<li>\n<a href="#heading-2">Heading 2</a>\n</li>\n</ul>\n</li>\n</ul>}

    assert_match(output_expected, output_actual)
  end

  def test_toc_if_requested
    # Create filter
    filter = ::Nanoc::Filters::Redcarpet.new

    # Run filter
    input = "A Title\n======"
    output_expected = %r{<ul>\n<li>\n<a href="#a-title">A Title</a>\n</li>\n</ul>\n<h1 id="a-title">A Title</h1>\n}
    output_actual   = filter.setup_and_run(input, with_toc: true)

    # Test
    assert_match(output_expected, output_actual)
  end
end
