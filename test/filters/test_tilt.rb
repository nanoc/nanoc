# encoding: utf-8

class Nanoc::Filters::TiltTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'tilt', 'haml' do
      filter = tilt_filter_for_item_with_extension('haml')
      assert_equal("<?xml version='1.0' encoding='utf-8' ?>\n", filter.run('!!! XML'))
    end
  end

  private
  def tilt_filter_for_item_with_extension(extension)
    ::Nanoc::Filters::Tilt.new(:item => Nanoc3::Item.new(
      'blah',
      { :extension => extension },
      '/blah/'))
  end
end

