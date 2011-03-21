# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::SlimTest < Nanoc3::TestCase

  def test_filter
    if_have 'slim' do
      # Create filter
      filter = ::Nanoc3::Filters::Slim.new({ :rabbit => 'The rabbit is on the branch.' })

      # Run filter (no assigns)
      result = filter.run('html')
      assert_match(/<html>.*<\/html>/, result)

      # Run filter (assigns without @)
      result = filter.run('p = rabbit')
      assert_equal("<p>The rabbit is on the branch.</p>", result)

      # Run filter (assigns with @)
      result = filter.run('p = @rabbit')
      assert_equal("<p>The rabbit is on the branch.</p>", result)
    end
  end
end
