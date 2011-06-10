# encoding: utf-8

class Nanoc3::Filters::MustacheTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'mustache' do
      # Create item
      item = Nanoc3::Item.new(
        'content',
        { :title => 'Max Payne', :protagonist => 'Max Payne' },
        '/games/max-payne/'
      )

      # Create filter
      filter = ::Nanoc3::Filters::Mustache.new({ :item => item })

      # Run filter
      result = filter.run('The protagonist of {{title}} is {{protagonist}}.')
      assert_equal('The protagonist of Max Payne is Max Payne.', result)
    end
  end

end
