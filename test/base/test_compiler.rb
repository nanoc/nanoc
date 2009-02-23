require 'test/helper'

class Nanoc::CompilerTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_run_without_item
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
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })
    site.expects(:pages).returns(pages)
    site.expects(:assets).returns(assets)

    # Set items' site
    (pages + assets).each { |item| item.site = site }

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.expects(:compile_rep).times(4)

    # Create rules
    File.open('tmp/Rules', 'w') do |io|
      io.write("page '*' do |p|\n")
      io.write("  p.write\n")
      io.write("end\n")
      io.write("\n")
      io.write("asset '*' do |a|\n")
      io.write("  a.write\n")
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
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })

    # Set item's site
    page.site = site

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.expects(:compile_rep)

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
    site.expects(:config).returns({ :output_dir => 'foo/bar/baz' })

    # Set item's site
    asset.site = site

    # Create compiler
    compiler = Nanoc::Compiler.new(site)
    compiler.expects(:compile_rep)

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
