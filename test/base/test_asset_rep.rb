require 'helper'

class Nanoc::AssetRepTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, '/foo/')
    asset.site = site

    # Get rep
    asset.build_reps
    asset_rep = asset.reps.first

    # Assert flags reset
    assert(asset_rep.instance_eval { !@compiled })
    assert(asset_rep.instance_eval { !@modified })
    assert(asset_rep.instance_eval { !@created })
    assert(asset_rep.instance_eval { !@filtered })
  end

  def test_to_proxy
    # Create asset defaults
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:asset_defaults).returns(asset_defaults)

    # Create asset
    asset = Nanoc::Asset.new(nil, { 'foo' => 'bar' }, '/foo/')
    asset.site = site

    # Get rep
    asset.build_reps
    asset_rep = asset.reps.first

    # Create proxy
    asset_rep_proxy = asset_rep.to_proxy

    # Check values
    assert_equal('bar', asset_rep_proxy.foo)
  end

  def test_created_modified_compiled
    # Create file
    File.open('tmp/test.txt', 'w') { |io| io.write('old stuff') }

    # Create data
    asset_defaults = Nanoc::AssetDefaults.new(:foo => 'bar')
    asset = Nanoc::Asset.new(File.new('tmp/test.txt'), {}, '/foo/')

    # Create site and other requisites
    stack = []
    compiler = mock
    compiler.stubs(:stack).returns(stack)
    router = mock
    router.expects(:disk_path_for).returns('tmp/out/foo/index.html')
    site = mock
    site.expects(:compiler).at_least_once.returns(compiler)
    site.expects(:router).returns(router)
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    asset.site = site

    # Get rep
    asset.build_reps
    asset_rep = asset.reps.first

    # Check
    assert(!asset_rep.created?)
    assert(!asset_rep.modified?)
    assert(!asset_rep.compiled?)

    # Compile asset rep
    asset_rep.compile(false, true)

    # Check
    assert(asset_rep.created?)
    assert(asset_rep.modified?)
    assert(asset_rep.compiled?)

    # Compile asset rep
    asset_rep.compile(false, true)

    # Check
    assert(!asset_rep.created?)
    assert(!asset_rep.modified?)
    assert(asset_rep.compiled?)

    # Edit and compile asset rep
    asset.instance_eval { @mtime = Time.now + 5 }
    File.open('tmp/test.txt', 'w') { |io| io.write('new stuff') }
    asset.instance_eval { @file = File.new('tmp/test.txt') }
    asset_rep.compile(false, true)

    # Check
    assert(!asset_rep.created?)
    assert(asset_rep.modified?)
    assert(asset_rep.compiled?)
  end

  def test_outdated
    # TODO implement
  end

  def test_disk_and_web_path
    # TODO implement
  end

  def test_attribute_named_with_custom_rep
    # TODO implement
  end

  def test_attribute_named_with_default_rep
    # TODO implement
  end

  def test_compile
    # TODO implement
  end

  def test_compile_even_when_not_outdated
    # TODO implement
  end

  def test_compile_from_scratch
    # TODO implement
  end

  def test_digest
    # TODO implement
  end

  def test_compile_binary
    # TODO implement
  end

  def test_compile_textual
    # TODO implement
  end

end
