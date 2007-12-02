require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class CoreExtArrayTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_array_pushing
    arr = []
    arr.pushing('foo') do
      assert_equal([ 'foo' ], arr)
      arr.pushing('bar') do
        assert_equal([ 'foo', 'bar' ], arr)
      end
      assert_equal([ 'foo' ], arr)
    end
    assert_equal([], arr)
  end

end
