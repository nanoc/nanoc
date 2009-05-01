require 'test/helper'

class Nanoc3::ItemRepTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_created_modified_compiled
    # TODO implement
  end

  def test_to_proxy
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:content, "blah blah blah")

    # Create item rep
    rep = Nanoc3::ItemRep.new(item, 'blah')

    # Create proxy
    rep_proxy = rep.to_proxy

    # Test
    assert_equal(rep, rep_proxy.instance_eval { @obj })
  end

  def test_not_outdated
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.now-500)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-800)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-900)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create output file
    File.open('output.html', 'w') { |io| io.write('Testing testing 123...') }
    File.utime(Time.now-100, Time.now-200, 'output.html')

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }

    # Test
    refute(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_outdated_if_mtime_nil
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, nil)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-800)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-900)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create output file
    File.open('output.html', 'w') { |io| io.write('Testing testing 123...') }
    File.utime(Time.now-100, Time.now-200, 'output.html')

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }

    # Test
    assert(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_outdated_if_force_outdated
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.now-500)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-800)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-900)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create output file
    File.open('output.html', 'w') { |io| io.write('Testing testing 123...') }
    File.utime(Time.now-100, Time.now-200, 'output.html')

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }
    rep.instance_eval { @force_outdated = true }

    # Test
    assert(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_outdated_if_compiled_file_doesnt_exist
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.now-500)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-800)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-900)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }

    # Test
    assert(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_outdated_if_source_file_too_old
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.now-100)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-800)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-900)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create output file
    File.open('output.html', 'w') { |io| io.write('Testing testing 123...') }
    File.utime(Time.now-500, Time.now-600, 'output.html')

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }

    # Test
    assert(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_outdated_if_layouts_outdated
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.now-500)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-100)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-900)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create output file
    File.open('output.html', 'w') { |io| io.write('Testing testing 123...') }
    File.utime(Time.now-200, Time.now-300, 'output.html')

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }

    # Test
    assert(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_outdated_if_code_outdated
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.now-500)
    item.expect(:[], false, [ :skip_output ])
    item.expect(:content, "blah blah blah")

    # Mock layouts
    layouts = [ mock ]
    layouts[0].stubs(:mtime).returns(Time.now-800)

    # Mock code
    code = mock
    code.stubs(:mtime).returns(Time.now-100)

    # Mock site
    site = mock
    site.stubs(:layouts).returns(layouts)
    site.stubs(:code).returns(code)
    item.stubs(:site).returns(site)

    # Create output file
    File.open('output.html', 'w') { |io| io.write('Testing testing 123...') }
    File.utime(Time.now-200, Time.now-300, 'output.html')

    # Create rep
    rep = Nanoc3::ItemRep.new(item, 'blah')
    rep.instance_eval { @raw_path = 'output.html' }

    # Test
    assert(rep.outdated?)
  ensure
    FileUtils.rm_f('output.html')
  end

  def test_filter
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = MiniTest::Mock.new
    item.expect(:content, %[<%= '<%= "blah" %' + '>' %>])
    item.expect(:site, site)
    item.stubs(:to_proxy).returns(nil)

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.content
      @content[:last] = @content[:raw]
    end

    # Filter once
    item_rep.filter(:erb)
    assert_equal(%[<%= "blah" %>], item_rep.instance_eval { @content[:last] })

    # Filter twice
    item_rep.filter(:erb)
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

  def test_layout
    # Mock layout
    layout = mock
    layout.stubs(:identifier).returns('/somelayout/')
    layout.stubs(:to_proxy).returns(nil)
    layout.stubs(:content).returns(%[<%= "blah" %>])

    # Mock compiler
    compiler = mock
    compiler.expects(:filter_name_for_layout).with(layout).returns(:erb)

    # Mock site
    site = mock
    site.stubs(:items).returns([])
    site.stubs(:config).returns([])
    site.stubs(:layouts).returns([ layout ])
    site.expects(:compiler).returns(compiler)

    # Mock item
    item = mock
    item.stubs(:content).returns(%[Hello.])
    item.stubs(:site).returns(site)
    item.stubs(:to_proxy).returns(nil)

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.content
      @content[:last] = @content[:raw]
    end

    # Layout
    item_rep.layout('/somelayout/')
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

  def test_snapshot
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:items, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = MiniTest::Mock.new
    item.expect(:content, %[<%= '<%= "blah" %' + '>' %>])
    item.expect(:site, site)
    item.stubs(:to_proxy).returns(nil)

    # Create item rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval do
      @content[:raw]  = item.content
      @content[:last] = @content[:raw]
    end

    # Filter while taking snapshots
    item_rep.snapshot(:foo)
    item_rep.filter(:erb)
    item_rep.snapshot(:bar)
    item_rep.filter(:erb)
    item_rep.snapshot(:qux)

    # Check snapshots
    assert_equal(%[<%= '<%= "blah" %' + '>' %>], item_rep.instance_eval { @content[:foo] })
    assert_equal(%[<%= "blah" %>],               item_rep.instance_eval { @content[:bar] })
    assert_equal(%[blah],                        item_rep.instance_eval { @content[:qux] })
  end

  def test_write
    # Mock site, router and item
    item = MiniTest::Mock.new
    item.expect(:content, "blah blah blah")

    # Create rep
    item_rep = Nanoc3::ItemRep.new(item, '/foo/')
    item_rep.instance_eval { @content[:last] = 'Lorem ipsum, etc.' }
    item_rep.raw_path = 'foo/bar/baz/quux.txt'

    # Write
    item_rep.write

    # Check
    assert(File.file?('foo/bar/baz/quux.txt'))
    assert_equal('Lorem ipsum, etc.', File.read('foo/bar/baz/quux.txt'))
  end

end
