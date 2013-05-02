# encoding: utf-8

class Nanoc::ChecksumStoreTest < Nanoc::TestCase

  def test_get_with_existing_object
    require 'pstore'

    # Create store
    FileUtils.mkdir_p('tmp')
    pstore = PStore.new('tmp/checksums')
    pstore.transaction do
      pstore[:data] = { [ :item, Nanoc::Identifier.from_string('/moo.md') ] => 'zomg' }
      pstore[:version] = 1
    end

    # Check
    store = Nanoc::ChecksumStore.new
    store.load
    obj = Nanoc::Item.new('Moo?', {}, '/moo.md')
    assert_equal 'zomg', store[obj]
  end

  def test_get_with_nonexistant_object
    store = Nanoc::ChecksumStore.new
    store.load

    # Check
    obj = Nanoc::Item.new('Moo?', {}, '/animals/cow.md')
    assert_equal nil, store[obj]
  end

end
