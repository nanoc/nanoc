require 'test/helper'

class Nanoc::AssetRepTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create asset defaults
    asset_defaults = Nanoc::Defaults.new(:foo => 'bar')

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
  end

  def test_to_proxy
    # Create asset defaults
    asset_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.stubs(:asset_defaults).returns(asset_defaults)

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
    asset_defaults = Nanoc::Defaults.new(:foo => 'bar')
    asset = Nanoc::Asset.new(File.new('tmp/test.txt'), {}, '/foo/')

    # Create site and other requisites
    router = MiniTest::Mock.new.expect(:disk_path_for, 'tmp/out/foo/index.html', [ nil ])
    site = MiniTest::Mock.new
    site.expect(:router, router)
    site.expect(:asset_defaults, asset_defaults)
    site.expect(:pages, [])
    site.expect(:assets, [])
    site.expect(:layouts, [])
    site.expect(:config, {})
    asset.site = site

    # Create compiler
    compiler = Nanoc::Compiler.new(nil)
    compiler.instance_eval { @stack = [] }

    # Get rep
    asset.build_reps
    asset_rep = asset.reps.first

    # Check
    assert(!asset_rep.created?)
    assert(!asset_rep.modified?)
    assert(!asset_rep.compiled?)

    # Compile asset rep
    compiler.compile_rep(asset_rep, false)

    # Check
    assert(asset_rep.created?)
    assert(asset_rep.modified?)
    assert(asset_rep.compiled?)

    # Compile asset rep
    compiler.compile_rep(asset_rep, false)

    # Check
    assert(!asset_rep.created?)
    assert(!asset_rep.modified?)
    assert(asset_rep.compiled?)
  end

  def test_outdated
    # Create asset defaults
    asset_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create layouts
    layouts = [
      Nanoc::Layout.new('layout 1', {}, '/layout1/'),
      Nanoc::Layout.new('layout 2', {}, '/layout2/')
    ]

    # Create code
    code = Nanoc::Code.new('def stuff ; "moo" ; end')

    # Create site
    site = mock
    site.expects(:asset_defaults).at_least_once.returns(asset_defaults)
    site.expects(:layouts).at_least_once.returns(layouts)
    site.expects(:code).at_least_once.returns(code)

    # Create asset
    asset = Nanoc::Asset.new("content", { 'foo' => 'bar' }, '/foo/')
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps[0]
    asset_rep.stubs(:disk_path).returns('tmp/out/foo/index.png')

    # Make everything up to date
    asset.instance_eval { @mtime = Time.now - 100 }
    FileUtils.mkdir_p('tmp/out/foo')
    File.open(asset_rep.disk_path, 'w') { |io| }
    File.utime(Time.now - 50, Time.now - 50, asset_rep.disk_path)
    asset_defaults.instance_eval { @mtime = Time.now - 100 }
    layouts.each { |l| l.instance_eval { @mtime = Time.now - 100 } }
    code.instance_eval { @mtime = Time.now - 100 }

    # Assert not outdated
    assert(!asset_rep.outdated?)

    # Check with nil mtime
    asset.instance_eval { @mtime = nil }
    assert(asset_rep.outdated?)
    asset.instance_eval { @mtime = Time.now - 100 }
    assert(!asset_rep.outdated?)

    # Check with non-existant output file
    FileUtils.rm_rf(asset_rep.disk_path)
    assert(asset_rep.outdated?)
    FileUtils.mkdir_p('tmp/out/foo')
    File.open(asset_rep.disk_path, 'w') { |io| }
    assert(!asset_rep.outdated?)

    # Check with older mtime
    asset.instance_eval { @mtime = Time.now }
    assert(asset_rep.outdated?)
    asset.instance_eval { @mtime = Time.now - 100 }
    assert(!asset_rep.outdated?)

    # Check with outdated asset defaults
    asset_defaults.instance_eval { @mtime = Time.now }
    assert(asset_rep.outdated?)
    asset_defaults.instance_eval { @mtime = nil }
    assert(asset_rep.outdated?)
    asset_defaults.instance_eval { @mtime = Time.now - 100 }
    assert(!asset_rep.outdated?)

    # Check with outdated code
    code.instance_eval { @mtime = Time.now }
    assert(asset_rep.outdated?)
    code.instance_eval { @mtime = nil }
    assert(asset_rep.outdated?)
    code.instance_eval { @mtime = Time.now - 100 }
    assert(!asset_rep.outdated?)
  end

  def test_disk_and_web_path
    # Create asset defaults
    asset_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create router
    router = mock
    router.stubs(:disk_path_for).returns('tmp/out/assets/path/index.html')
    router.stubs(:web_path_for).returns('/assets/path/')

    # Create site and compiler
    compiler = mock
    site = mock
    site.stubs(:asset_defaults).returns(asset_defaults)
    site.stubs(:router).returns(router)
    site.stubs(:compiler).returns(compiler)

    # Create asset
    asset = Nanoc::Asset.new(nil, { :attr => 'ibutes' }, '/path/')
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps.find { |r| r.name == :default }
    compiler.stubs(:compile_rep).with(asset_rep, false)

    # Check
    assert_equal('tmp/out/assets/path/index.html', asset_rep.disk_path)
    assert_equal('/assets/path/',                  asset_rep.web_path)
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

  def test_compile_force
    # TODO implement
  end

  def test_compile_textual
    # TODO implement
  end

end
