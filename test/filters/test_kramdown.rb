# encoding: utf-8

class Nanoc::Filters::KramdownTest < Nanoc::TestCase

  def test_filter
    if_have 'kramdown' do
      # Create filter
      filter = ::Nanoc::Filters::Kramdown.new

      # Run filter
      result = filter.setup_and_run("This is _so_ **cool**!")
      assert_equal("<p>This is <em>so</em> <strong>cool</strong>!</p>\n", result)
    end
  end

end
