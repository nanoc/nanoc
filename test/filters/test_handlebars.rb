# encoding: utf-8

class Nanoc::Filters::HandlebarsTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'handlebars' do
      # Create data
      item = Nanoc::Item.new(
        'content',
        { :title => 'Max Payne', :protagonist => 'Max Payne', :location => 'here' },
        '/games/max-payne/')
      layout = Nanoc::Layout.new(
        'layout content',
        { :name => 'Max Payne' },
        '/default/')
      config = { :animals => 'cats and dogs' }

      # Create filter
      assigns = {
        :item    => item,
        :layout  => layout,
        :config  => config,
        :content => 'No Payne No Gayne'
      }
      Handlebars.register_helper(:upcase) { |b| b.call.upcase }
      filter = ::Nanoc::Filters::Handlebars.new(assigns)

      # Run filter
      result = filter.run('{{protagonist}} says: {{yield}}.')
      assert_equal('Max Payne says: No Payne No Gayne.', result)
      result = filter.run('We can’t stop {{item.location}}! This is the {{layout.name}} layout!')
      assert_equal('We can’t stop here! This is the Max Payne layout!', result)
      result = filter.run('It’s raining {{config.animals}} here!')
      assert_equal('It’s raining cats and dogs here!', result)
      result = filter.run('I am {{#upcase}}shouting{{/upcase}}!')
      assert_equal('I am SHOUTING!', result)
    end
  end

end
