class Nanoc::Int::ChecksumStoreTest < Nanoc::TestCase
  def test_get_with_existing_object
    require 'pstore'

    # Create store
    FileUtils.mkdir_p('tmp')
    pstore = PStore.new('tmp/checksums')
    pstore.transaction do
      pstore[:data] = { [:item, '/moo/'] => 'zomg' }
      pstore[:version] = 2
    end

    # Check
    store = Nanoc::Int::ChecksumStore.new
    store.load
    obj = Nanoc::Int::Item.new('Moo?', {}, '/moo/')
    assert_equal 'zomg', store[obj]
  end

  def test_get_with_nonexistant_object
    store = Nanoc::Int::ChecksumStore.new
    store.load

    # Check
    obj = Nanoc::Int::Item.new('Moo?', {}, '/animals/cow/')
    assert_equal nil, store[obj]
  end
end
