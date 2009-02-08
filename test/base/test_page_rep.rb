require 'test/helper'

class Nanoc::PageRepTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("some content", { 'foo' => 'bar' }, '/foo/')
    page.site = site

    # Get rep
    page.build_reps
    page_rep = page.reps.first

    # Assert content set
    assert_equal(nil, page_rep.instance_eval { @content[:pre]  })
    assert_equal(nil, page_rep.instance_eval { @content[:post] })

    # Assert flags reset
    assert(page_rep.instance_eval { !@compiled })
    assert(page_rep.instance_eval { !@modified })
    assert(page_rep.instance_eval { !@created })
  end

  def test_created_modified_compiled
    # Create data
    page = Nanoc::Page.new('content', { 'foo' => 'bar' }, '/foo/')

    # Create site and other requisites
    site = mock
    page.site = site

    # Create compiler
    compiler = Nanoc::Compiler.new(nil)
    compiler.instance_eval { @stack = [] }
    compiler.add_page_rule('*', lambda { |p| p.write })

    # Get rep
    page.build_reps
    page_rep = page.reps.first
    page_rep.stubs(:disk_path).returns('tmp/out/foo/index.html')

    # Check
    assert(!page_rep.created?)
    assert(!page_rep.modified?)
    assert(!page_rep.compiled?)

    # Compile page rep
    compiler.compile_rep(page_rep, false)

    # Check
    assert(page_rep.created?)
    assert(page_rep.modified?)
    assert(page_rep.compiled?)

    # Compile page rep
    compiler.compile_rep(page_rep, false)

    # Check
    assert(!page_rep.created?)
    assert(!page_rep.modified?)
    assert(page_rep.compiled?)
  end

  def test_content_pre_not_yet_compiled
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new(
      "content <%= 'foo' %>",
      { :filters_pre => [ 'erb' ] },
      '/path/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Mock compiler
    compiler = mock
    compiler.expects(:compile_rep).with(page_rep, false)
    site.expects(:compiler).returns(compiler)

    # Check
    page_rep.content_at_snapshot(:pre)
  end

  def test_content_pre_already_compiled
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]
    page_rep.instance_eval { @content = { :pre => 'pre!', :post => 'post!' } }

    # Check
    assert_equal('pre!', page_rep.content_at_snapshot(:pre))
  end

  def test_content_post_not_yet_compiled
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]

    # Mock compiler
    compiler = mock
    site.expects(:compiler).returns(compiler)
    compiler.expects(:compile_rep).with(page_rep, false)

    # Check
    page_rep.content_at_snapshot(:post)
  end

  def test_content_post_already_compiled
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps[0]
    page_rep.instance_eval do
      @compiled = true
      @content[:pre] = 'pre!'
      @content[:post] = 'post!'
    end

    # Check
    assert_equal('post!', page_rep.content_at_snapshot(:post))
  end

end
