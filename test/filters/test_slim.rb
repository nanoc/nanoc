# encoding: utf-8

class Nanoc::Filters::SlimTest < Nanoc::TestCase

  def test_filter
    if_have 'slim' do
      # Create filter
      filter = ::Nanoc::Filters::Slim.new({ :rabbit => 'The rabbit is on the branch.' })

      # Run filter (no assigns)
      result = filter.setup_and_run('html')
      assert_match(/<html>.*<\/html>/, result)

      # Run filter (assigns without @)
      result = filter.setup_and_run('p = rabbit')
      assert_equal("<p>The rabbit is on the branch.</p>", result)

      # Run filter (assigns with @)
      result = filter.setup_and_run('p = @rabbit')
      assert_equal("<p>The rabbit is on the branch.</p>", result)
    end
  end

  def test_filter_with_yield
    if_have 'slim' do
      filter = ::Nanoc::Filters::Slim.new({ :content => 'The rabbit is on the branch.' })

      result = filter.setup_and_run('p = yield')
      assert_equal("<p>The rabbit is on the branch.</p>", result)
    end
  end

end
