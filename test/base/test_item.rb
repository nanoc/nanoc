# encoding: utf-8

class Nanoc::ItemTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_initialize_with_attributes_with_string_keys
    item = Nanoc::Item.new("foo", { 'abc' => 'xyz' }, '/foo/')

    assert_equal nil,   item.attributes['abc']
    assert_equal 'xyz', item.attributes[:abc]
  end

  def test_initialize_with_unclean_identifier
    item = Nanoc::Item.new("foo", {}, '/foo')

    assert_equal '/foo/', item.identifier
  end

  def test_frozen_identifier
    item = Nanoc::Item.new("foo", {}, '/foo')

    raised = false
    begin
      item.identifier.chop!
    rescue => error
      raised = true
      assert_match /(^can't modify frozen [Ss]tring|^unable to modify frozen object$)/, error.message
    end
    assert raised, 'Should have raised when trying to modify a frozen string'
  end

  def test_lookup
    # Create item
    item = Nanoc::Item.new(
      "content",
      { :one => 'one in item' },
      '/path/'
    )

    # Test finding one
    assert_equal('one in item', item[:one])

    # Test finding two
    assert_equal(nil, item[:two])
  end

  def test_set_attribute
    item = Nanoc::Item.new("foo", {}, '/foo')
    assert_equal nil, item[:motto]

    item[:motto] = 'More human than human'
    assert_equal 'More human than human', item[:motto]
  end

  def test_compiled_content_with_default_rep_and_default_snapshot
    # Mock rep
    rep = Object.new
    def rep.name ; :default ; end
    def rep.compiled_content(params)
      "content at #{params[:snapshot].inspect}"
    end

    # Mock item
    item = Nanoc::Item.new("foo", {}, '/foo')
    item.expects(:reps).returns([ rep ])

    # Check
    assert_equal 'content at nil', item.compiled_content
  end

  def test_compiled_content_with_custom_rep_and_default_snapshot
    # Mock reps
    rep = Object.new
    def rep.name ; :foo ; end
    def rep.compiled_content(params)
      "content at #{params[:snapshot].inspect}"
    end

    # Mock item
    item = Nanoc::Item.new("foo", {}, '/foo')
    item.expects(:reps).returns([ rep ])

    # Check
    assert_equal 'content at nil', item.compiled_content(:rep => :foo)
  end

  def test_compiled_content_with_default_rep_and_custom_snapshot
    # Mock reps
    rep = Object.new
    def rep.name ; :default ; end
    def rep.compiled_content(params)
      "content at #{params[:snapshot].inspect}"
    end

    # Mock item
    item = Nanoc::Item.new("foo", {}, '/foo')
    item.expects(:reps).returns([ rep ])

    # Check
    assert_equal 'content at :blah', item.compiled_content(:snapshot => :blah)
  end

  def test_compiled_content_with_custom_nonexistant_rep
    # Mock item
    item = Nanoc::Item.new("foo", {}, '/foo')
    item.expects(:reps).returns([])

    # Check
    assert_raises(Nanoc::Errors::Generic) do
      item.compiled_content(:rep => :lkasdhflahgwfe)
    end
  end

  def test_path_with_default_rep
    # Mock reps
    rep = mock
    rep.expects(:name).returns(:default)
    rep.expects(:path).returns('the correct path')

    # Mock item
    item = Nanoc::Item.new("foo", {}, '/foo')
    item.expects(:reps).returns([ rep ])

    # Check
    assert_equal 'the correct path', item.path
  end

  def test_path_with_custom_rep
    # Mock reps
    rep = mock
    rep.expects(:name).returns(:moo)
    rep.expects(:path).returns('the correct path')

    # Mock item
    item = Nanoc::Item.new("foo", {}, '/foo')
    item.expects(:reps).returns([ rep ])

    # Check
    assert_equal 'the correct path', item.path(:rep => :moo)
  end

  def test_freeze_should_disallow_changes
    item = Nanoc::Item.new("foo", { :a => { :b => 123 }}, '/foo/')
    item.freeze

    raised = false
    begin
      item[:abc] = '123'
    rescue => e
      raised = true
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised

    raised = false
    begin
      item[:a][:b] = '456'
    rescue => e
      raised = true
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised
  end

  def test_dump_and_load
    item = Nanoc::Item.new(
      "foobar",
      { :a => { :b => 123 }},
      '/foo/')

    item = Marshal.load(Marshal.dump(item))

    assert_equal '/foo/', item.identifier
    assert_equal 'foobar', item.raw_content
    assert_equal({ :a => { :b => 123 }}, item.attributes)
  end

end
