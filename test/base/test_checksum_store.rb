# encoding: utf-8

require 'test/helper'

class Nanoc3::ChecksumStoreTest < Nanoc3::TestCase

  def setup
    super

    @site = mock
    config = { :tmp_dir => 'tmp' }
    @site.stubs(:config).returns(config)
    @store = Nanoc3::ChecksumStore.new(@site)
  end

  def test_get_with_existing_object
    require 'pstore'

    # Create store
    FileUtils.mkdir_p(File.dirname(@store.filename))
    pstore = PStore.new(@store.filename)
    pstore.transaction do
      pstore[:data] = { [ :item, '/moo/' ] => 'zomg' }
      pstore[:version] = 1
    end

    # Check
    @store.load
    obj = Nanoc3::Item.new('Moo?', {}, '/moo/')
    assert_equal 'zomg', @store.old_checksum_for(obj)
  end

  def test_get_with_nonexistant_object
    @store.load

    # Check
    obj = Nanoc3::Item.new('Moo?', {}, '/animals/cow/')
    new_checksum = Nanoc3::Checksummer.checksum_for_string('Moo?') + '-' +
      Nanoc3::Checksummer.checksum_for_hash({})
    assert_equal nil,          @store.old_checksum_for(obj)
    assert_equal new_checksum, @store.new_checksum_for(obj)
  end

  def test_store
    obj = Nanoc3::Item.new('Moo?', {}, '/animals/cow/')
    new_checksum = Nanoc3::Checksummer.checksum_for_string('Moo?') + '-' +
      Nanoc3::Checksummer.checksum_for_hash({})

    compiler = mock
    compiler.stubs(:objects).returns([ obj ])
    @site.stubs(:compiler).returns(compiler)

    @store.load

    @store.store

    @store = Nanoc3::ChecksumStore.new(@site)
    @store.load

    assert_equal new_checksum, @store.old_checksum_for(obj)
    assert_equal new_checksum, @store.new_checksum_for(obj)
  end

end
