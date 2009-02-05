require 'test/helper'

class Nanoc::CompilerTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_run_without_obj
    # Create pages
    pages = [
      Nanoc::Page.new('page one', {}, '/page1/'),
      Nanoc::Page.new('page two', {}, '/page2/')
    ]
    assets = [
      Nanoc::Asset.new(nil, {}, '/asset1/'),
      Nanoc::Asset.new(nil, {}, '/asset2/')
    ]

    # Create site
    site = mock
    site.expects(:load_data)
    site.expects(:config).returns({ :output_dir => 'tmp/blah' })
    site.expects(:asset_defaults).times(2).returns(Nanoc::Defaults.new({}))
    site.expects(:page_defaults).times(2).returns(Nanoc::Defaults.new({}))
    site.expects(:pages).returns(pages)
    site.expects(:assets).returns(assets)

    # Create reps and setup compilation
    (pages + assets).each do |obj|
      # Build reps
      obj.site = site
      obj.build_reps
      rep = obj.reps[0]

      # Setup compilation
      rep.expects(:compile).with(false, false)
    end

    # Create compiler
    compiler = Nanoc::Compiler.new(site)

    # Run
    compiler.run

    # Make sure output dir is created
    assert(File.directory?('tmp/blah'))
  end

  def test_run_with_page_rep
    # Create page
    page = Nanoc::Page.new('page one', {}, '/page1/')

    # Create site
    site = mock
    site.expects(:load_data)
    site.expects(:config).returns({ :output_dir => 'tmp/blah' })
    site.expects(:page_defaults).returns(Nanoc::Defaults.new({}))

    # Build reps
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Setup compilation
    page_rep.expects(:compile).with(false, false)

    # Create compiler
    compiler = Nanoc::Compiler.new(site)

    # Run
    compiler.run([ page ])

    # Make sure output dir is created
    assert(File.directory?('tmp/blah'))
  end

  def test_run_with_asset_rep
    # Create asset
    asset = Nanoc::Asset.new('asset one', {}, '/asset1/')

    # Create site
    site = mock
    site.expects(:load_data)
    site.expects(:config).returns({ :output_dir => 'tmp/blah' })
    site.expects(:asset_defaults).returns(Nanoc::Defaults.new({}))

    # Build reps
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps[0]

    # Setup compilation
    asset_rep.expects(:compile).with(false, false)

    # Create compiler
    compiler = Nanoc::Compiler.new(site)

    # Run
    compiler.run([ asset ])

    # Make sure output dir is created
    assert(File.directory?('tmp/blah'))
  end

end
