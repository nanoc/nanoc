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
      result = filter.run("> Quote")
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
        output_actual   = filter.run(input, :options => { :strikethrough => true })
      else
        input           = "The quotation 'marks' sure make this look sarcastic!"
        output_expected = /The quotation &lsquo;marks&rsquo; sure make this look sarcastic!/
        output_actual   = filter.run(input, :options => [ :smart ])
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
      output_actual   = filter.run(input)
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
        output_actual   = filter.run(input, :renderer_options => { :xhtml => true })
      else
        output_actual   = filter.run(input, :options => [ :xhtml ])
      end
      assert_match(output_expected, output_actual)
    end
  end

end
