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
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })
    site.expects(:pages).returns(pages)
    site.expects(:assets).returns(assets)

    # Create reps and setup compilation
    (pages + assets).each do |obj|
      obj.site = site
      obj.build_reps
      rep = obj.reps[0]
    end

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.expects(:compile_rep).times(4)

    # Create rules
    File.open('tmp/Rules', 'w') do |io|
      io.write("page '*' do |p|\n")
      io.write("  p.write\n")
      io.write("end\n")
    end

    # Run
    FileUtils.cd('tmp') { compiler.run }

    # Make sure output dir is created
    assert(File.directory?('tmp/foo/bar/baz'))
  end

  def test_run_with_page_rep
    # Create page
    page = Nanoc::Page.new('page one', {}, '/page1/')

    # Create site
    site = mock
    site.expects(:load_data)
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })

    # Build reps
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.expects(:compile_rep).with(page_rep, false)

    # Create rules
    File.open('tmp/Rules', 'w') do |io|
      io.write("page '*' do |p|\n")
      io.write("  p.write\n")
      io.write("end\n")
    end

    # Run
    FileUtils.cd('tmp') { compiler.run([ page ]) }

    # Make sure output dir is created
    assert(File.directory?('tmp/foo/bar/baz'))
  end

  def test_run_with_asset_rep
    # Create asset
    asset = Nanoc::Asset.new('asset one', {}, '/asset1/')

    # Create site
    site = mock
    site.expects(:load_data)
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })

    # Build reps
    asset.site = site
    asset.build_reps
    asset_rep = asset.reps[0]

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.expects(:compile_rep).with(asset_rep, false)

    # Create rules
    File.open('tmp/Rules', 'w') do |io|
      io.write("asset '*' do |a|\n")
      io.write("  a.write\n")
      io.write("end\n")
    end

    # Run
    FileUtils.cd('tmp') { compiler.run([ asset ]) }

    # Make sure output dir is created
    assert(File.directory?('tmp/foo/bar/baz'))
  end

end
