require 'test/helper'

class Nanoc::Filters::ErubisTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new({ :location => 'a cheap motel' })

      # Run filter
      result = filter.run('<%= "I was hiding in #{@location}." %>')
      assert_equal('I was hiding in a cheap motel.', result)
    end
  end

  def test_filter_error
    if_have 'erubis' do
      # Create filter
      filter = ::Nanoc::Filters::Erubis.new

      # Run filter
      raised = false
      begin
        filter.run('<%= this isn\'t really ruby so it\'ll break, muahaha %>')
      rescue SyntaxError => e
        assert_match '?', e.backtrace[0]
        raised = true
      end
      assert raised
    end
  end

end
