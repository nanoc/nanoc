class Nanoc::Filters::KramdownTest < Nanoc::TestCase
  def test_filter
    if_have 'kramdown' do
      # Create filter
      filter = ::Nanoc::Filters::Kramdown.new

      # Run filter
      result = filter.setup_and_run('This is _so_ **cool**!')
      assert_equal("<p>This is <em>so</em> <strong>cool</strong>!</p>\n", result)
    end
  end

  def test_warnings
    if_have 'kramdown' do
      # Create filter
      filter = ::Nanoc::Filters::Kramdown.new

      # Run filter
      io = capturing_stdio do
        filter.setup_and_run('{:foo}this is bogus')
      end
      assert_empty io[:stdout]
      assert_equal "kramdown warning: Found span IAL after text - ignoring it\n", io[:stderr]
    end
  end
end
