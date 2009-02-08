require 'test/helper'

class Nanoc::PageRepTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create page defaults
    page_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

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
    page_defaults = Nanoc::Defaults.new(:foo => 'bar')
    layout = Nanoc::Layout.new('[<%= @page.content %>]', {}, '/default/')
    page = Nanoc::Page.new('content', { 'foo' => 'bar' }, '/foo/')

    # Create site and other requisites
    site = mock
    site.expects(:config).at_least_once.returns({})
    site.expects(:page_defaults).at_least_once.returns(page_defaults)
    site.expects(:pages).at_least_once.returns([ page ])
    site.expects(:assets).at_least_once.returns([])
    site.expects(:layouts).at_least_once.returns([ layout ])
    page.site = site

    # Create compiler
    compiler = Nanoc::Compiler.new(nil)
    compiler.instance_eval { @stack = [] }

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

  def test_attribute_named_with_custom_rep
    # Should check in
    # 1. page rep
    # 2. page default's page rep
    # 3. hardcoded defaults

    # Create page defaults
    page_defaults = Nanoc::Defaults.new({
      :reps => { :custom => {
        :one => 'one in page defaults rep',
        :two => 'two in page defaults rep'
      }}
    })

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page and rep
    page = Nanoc::Page.new(
      "content",
      { :reps => { :custom => { :one => 'one in page rep' } } },
      '/path/'
    )
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :custom }

    # Test finding one
    assert_equal('one in page rep', page_rep.attribute_named(:one))

    # Test finding two
    assert_equal('two in page defaults rep', page_rep.attribute_named(:two))

    # Test finding three
    assert_equal('default', page_rep.attribute_named(:layout))
  end

  def test_attribute_named_with_default_rep
    # Should check in
    # 1. page rep
    # 2. page
    # 3. page defaults' page rep
    # 4. page defaults
    # 5. hardcoded defaults

    # Create page defaults
    page_defaults = Nanoc::Defaults.new({
      :one    => 'one in page defaults',
      :two    => 'two in page defaults',
      :three  => 'three in page defaults',
      :four   => 'four in page defaults',
      :reps => { :default => {
        :one    => 'one in page defaults rep',
        :two    => 'two in page defaults rep',
        :three  => 'three in page defaults rep'
      }}
    })

    # Create site
    site = mock
    site.expects(:page_defaults).at_least_once.returns(page_defaults)

    # Create page and rep
    page_attrs = {
      :oen  => 'one in page',
      :two  => 'two in page',
      :reps => { :default => { :one => 'one in page rep' } }
    }
    page = Nanoc::Page.new('content', page_attrs, '/path/')
    page.site = site
    page.build_reps
    page_rep = page.reps.find { |r| r.name == :default }

    # Test finding one
    assert_equal('one in page rep', page_rep.attribute_named(:one))

    # Test finding two
    assert_equal('two in page', page_rep.attribute_named(:two))

    # Test finding three
    assert_equal('three in page defaults rep', page_rep.attribute_named(:three))

    # Test finding four
    assert_equal('four in page defaults', page_rep.attribute_named(:four))

    # Test finding five
    assert_equal('default', page_rep.attribute_named(:layout))
  end

  def test_content_pre_not_yet_compiled
    # Create page defaults
    page_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

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
    # Create page defaults
    page_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.stubs(:page_defaults).returns(page_defaults)

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
    # Create page defaults
    page_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

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
    # Create page defaults
    page_defaults = Nanoc::Defaults.new(:foo => 'bar')

    # Create site
    site = mock
    site.expects(:page_defaults).returns(page_defaults)

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
