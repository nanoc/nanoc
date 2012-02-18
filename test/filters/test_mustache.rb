# encoding: utf-8

class Nanoc::Filters::MustacheTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'mustache' do
      # Create item
      item = Nanoc::Item.new(
        'content',
        { :title => 'Max Payne', :protagonist => 'Max Payne' },
        '/games/max-payne/'
      )

      # Create filter
      filter = ::Nanoc::Filters::Mustache.new({ :item => item })

      # Run filter
      result = filter.run('The protagonist of {{title}} is {{protagonist}}.')
      assert_equal('The protagonist of Max Payne is Max Payne.', result)
    end
  end

  def test_filter_with_yield
    if_have 'mustache' do
      # Create item
      item = Nanoc::Item.new(
        'content',
        { :title => 'Max Payne', :protagonist => 'Max Payne' },
        '/games/max-payne/'
      )

      # Create filter
      filter = ::Nanoc::Filters::Mustache.new(
        { :content => 'No Payne No Gayne', :item => item })

      # Run filter
      result = filter.run('Max says: {{yield}}.')
      assert_equal('Max says: No Payne No Gayne.', result)
    end
  end

end
