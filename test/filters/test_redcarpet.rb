# encoding: utf-8

class Nanoc::Filters::RedcarpetTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_find
    refute Nanoc::Filter.named(:redcarpet).nil?
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
      input           = "The quotation 'marks' sure make this look sarcastic!"
      output_expected = /The quotation &lsquo;marks&rsquo; sure make this look sarcastic!/
      output_actual   = filter.run(input, :options => [ :smart ])
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
      output_actual   = filter.run(input, :options => [ :xhtml ])
      assert_match(output_expected, output_actual)
    end
  end

end
