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

  def test_tmp_path_with_nil_env
    tmp_path_for_checksum = Nanoc::Int::Store.tmp_path_for(env_name: nil, store_name: 'checksum')
    assert_equal('tmp/checksum', tmp_path_for_checksum)
  end

  def test_tmp_path_with_test_env
    tmp_path_for_checksum = Nanoc::Int::Store.tmp_path_for(env_name: 'test', store_name: 'checksum')
    tmp_path_for_dependencies = Nanoc::Int::Store.tmp_path_for(env_name: 'test', store_name: 'dependencies')
    assert_equal('tmp/test/checksum', tmp_path_for_checksum)
    assert_equal('tmp/test/dependencies', tmp_path_for_dependencies)
  end
end
