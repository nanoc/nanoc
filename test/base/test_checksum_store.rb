# encoding: utf-8

require 'test/helper'

class Nanoc3::ChecksumStoreTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_get_with_existing_object
    require 'pstore'

    # Create store
    FileUtils.mkdir_p('tmp')
    pstore = PStore.new('tmp/checksums')
    pstore.transaction do
      pstore[:data] = { [ :item, '/moo/' ] => 'zomg' }
      pstore[:version] = 1
    end

    # Check
    store = Nanoc3::ChecksumStore.new
    store.load
    obj = Nanoc3::Item.new('Moo?', {}, '/moo/')
    assert_equal 'zomg', store.old_checksum_for(obj)
  end

  def test_get_with_nonexistant_object
    store = Nanoc3::ChecksumStore.new
    store.load

    # Check
    obj = Nanoc3::Item.new('Moo?', {}, '/animals/cow/')
    new_checksum = Nanoc3::Checksummer.checksum_for_string('Moo?') + '-' +
      Nanoc3::Checksummer.checksum_for_hash({})
    assert_equal nil,          store.old_checksum_for(obj)
    assert_equal new_checksum, store.new_checksum_for(obj)
  end

  def test_store
    obj = Nanoc3::Item.new('Moo?', {}, '/animals/cow/')
    new_checksum = Nanoc3::Checksummer.checksum_for_string('Moo?') + '-' +
      Nanoc3::Checksummer.checksum_for_hash({})

    compiler = mock
    compiler.stubs(:objects).returns([ obj ])

    site = mock
    site.stubs(:compiler).returns(compiler)

    store = Nanoc3::ChecksumStore.new(:site => site)
    store.load

    store.store
    store = Nanoc3::ChecksumStore.new(:site => site)
    store.load

    assert_equal new_checksum, store.old_checksum_for(obj)
    assert_equal new_checksum, store.new_checksum_for(obj)
  end

end
