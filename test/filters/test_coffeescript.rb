# encoding: utf-8

class Nanoc::Filters::CoffeeScriptTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'coffee-script' do
      # Create filter
      filter = ::Nanoc::Filters::CoffeeScript.new

      # Run filter (no assigns)
      result = filter.run('alert 42')
      assert_equal("(function() { alert(42); }).call(this); ", result.gsub(/\s+/, ' '))
    end
  end

end
