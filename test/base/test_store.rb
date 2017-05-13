# frozen_string_literal: true

require 'helper'

class Nanoc::Int::StoreTest < Nanoc::TestCase
  class TestStore < Nanoc::Int::Store
    def data
      @data
    end

    def data=(new_data)
      @data = new_data
    end
  end

  def test_delete_and_reload_on_error
    store = TestStore.new('test.db', 1)

    # Create
    store.load
    store.data = { fun: 'sure' }
    store.store

    # Test stored values
    store = TestStore.new('test.db', 1)
    store.load
    assert_equal({ fun: 'sure' }, store.data)

    # Mess up
    File.open('test.db', 'w') do |io|
      io << 'Damn {}#}%@}$^)@&$&*^#@ broken stores!!!'
    end

    # Reload
    store = TestStore.new('test.db', 1)
    store.load
    assert_equal(nil, store.data)
  end
end
