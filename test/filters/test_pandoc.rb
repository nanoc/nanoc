# encoding: utf-8

class Nanoc::Filters::PandocTest < Nanoc::TestCase

  def test_filter
    if_have 'pandoc-ruby' do
      skip_unless_have_command "pandoc"

      # Create filter
      filter = ::Nanoc::Filters::Pandoc.new

      # Run filter
      result = filter.setup_and_run("# Heading\n")
      assert_match(%r{<h1 id=\"heading\">Heading</h1>\s*}, result)
    end
  end

end
