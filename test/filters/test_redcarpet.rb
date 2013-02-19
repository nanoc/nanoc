# encoding: utf-8

class Nanoc::Filters::RedcarpetTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_find
    if_have 'redcarpet' do
      refute Nanoc::Filter.named(:redcarpet).nil?
    end
  end

  def test_filter
    if_have 'redcarpet' do
      # Create filter
      filter = ::Nanoc::Filters::Redcarpet.new

      # Run filter
      result = filter.setup_and_run("> Quote")
      assert_match(/<blockquote>\s*<p>Quote<\/p>\s*<\/blockquote>/, result)
    end
  end

  def test_with_extensions
    if_have 'redcarpet' do
      # Create filter
      filter = ::Nanoc::Filters::Redcarpet.new

      # Run filter
      if ::Redcarpet::VERSION > '2'
        input           = "this is ~~good~~ bad"
        output_expected = /this is <del>good<\/del> bad/
        output_actual   = filter.setup_and_run(input, :options => { :strikethrough => true })
      else
        input           = "The quotation 'marks' sure make this look sarcastic!"
        output_expected = /The quotation &lsquo;marks&rsquo; sure make this look sarcastic!/
        output_actual   = filter.setup_and_run(input, :options => [ :smart ])
      end
      assert_match(output_expected, output_actual)
    end
  end

  def test_html_by_default
    if_have 'redcarpet' do
      # Create filter
      filter = ::Nanoc::Filters::Redcarpet.new

      # Run filter
      input           = "![Alt](/path/to/img 'Title')"
      output_expected = %r{<img src="/path/to/img" alt="Alt" title="Title">}
      output_actual   = filter.setup_and_run(input)
      assert_match(output_expected, output_actual)
    end
  end

  def test_xhtml_if_requested
    if_have 'redcarpet' do
      # Create filter
      filter = ::Nanoc::Filters::Redcarpet.new

      # Run filter
      input           = "![Alt](/path/to/img 'Title')"
      output_expected = %r{<img src="/path/to/img" alt="Alt" title="Title"/>}
      if ::Redcarpet::VERSION > '2'
        output_actual   = filter.setup_and_run(input, :renderer_options => { :xhtml => true })
      else
        output_actual   = filter.setup_and_run(input, :options => [ :xhtml ])
      end
      assert_match(output_expected, output_actual)
    end
  end

  def test_toc_if_requested
    if_have 'redcarpet' do
      # Create filter
      filter = ::Nanoc::Filters::Redcarpet.new

      # Run filter
      input = "A Title\n======"
      if ::Redcarpet::VERSION > '2'
        output_expected = %r{<ul>\n<li>\n<a href="#toc_0">A Title</a>\n</li>\n</ul>\n<h1 id="toc_0">A Title</h1>\n}
        output_actual   = filter.setup_and_run(input, :options => { :with_toc => true })
      else
        output_expected = %r{<h1>A Title</h1>\n}
        output_actual   = filter.setup_and_run(input)
      end
      assert_match(output_expected, output_actual)
    end
  end

end
