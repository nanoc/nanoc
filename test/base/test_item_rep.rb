class Nanoc::Int::ItemRepTest < Nanoc::TestCase
  def test_compiled_content_with_only_last_available
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.snapshot_contents = {
      last: Nanoc::Int::TextualContent.new('last content'),
    }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content
  end

  def test_compiled_content_with_pre_and_last_available
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.snapshot_contents = {
      pre: Nanoc::Int::TextualContent.new('pre content'),
      last: Nanoc::Int::TextualContent.new('last content'),
    }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'pre content', rep.compiled_content
  end

  def test_compiled_content_with_custom_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.snapshot_contents = {
      pre: Nanoc::Int::TextualContent.new('pre content'),
      last: Nanoc::Int::TextualContent.new('last content'),
    }
    rep.expects(:compiled?).returns(true)

    # Check
    assert_equal 'last content', rep.compiled_content(snapshot: :last)
  end

  def test_compiled_content_with_invalid_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.snapshot_contents = {
      pre: Nanoc::Int::TextualContent.new('pre content'),
      last: Nanoc::Int::TextualContent.new('last content'),
    }

    # Check
    assert_raises Nanoc::Int::Errors::NoSuchSnapshot do
      rep.compiled_content(snapshot: :klsjflkasdfl)
    end
  end

  def test_compiled_content_with_uncompiled_content
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)

    # Check
    assert_raises(Nanoc::Int::Errors::UnmetDependency) do
      rep.compiled_content
    end
  end

  def test_compiled_content_with_moving_pre_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)
    rep.snapshot_contents = {
      pre: Nanoc::Int::TextualContent.new('pre!'),
      last: Nanoc::Int::TextualContent.new('last!'),
    }

    # Check
    assert_raises(Nanoc::Int::Errors::UnmetDependency) do
      rep.compiled_content(snapshot: :pre)
    end
  end

  def test_compiled_content_with_non_moving_pre_snapshot
    # Create rep
    item = Nanoc::Int::Item.new(
      'blah blah', {}, '/',
    )
    rep = Nanoc::Int::ItemRep.new(item, nil)
    rep.expects(:compiled?).returns(false)
    rep.snapshot_defs = [
      Nanoc::Int::SnapshotDef.new(:pre, true),
    ]
    rep.snapshot_contents = {
      pre: Nanoc::Int::TextualContent.new('pre!'),
      post: Nanoc::Int::TextualContent.new('post!'),
      last: Nanoc::Int::TextualContent.new('last!'),
    }

    # Check
    assert_equal 'pre!', rep.compiled_content(snapshot: :pre)
  end

  def test_access_compiled_content_of_binary_item
    content = Nanoc::Int::BinaryContent.new(File.expand_path('content/somefile.dat'))
    item = Nanoc::Int::Item.new(content, {}, '/somefile/')
    item_rep = Nanoc::Int::ItemRep.new(item, :foo)
    assert_raises(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem) do
      item_rep.compiled_content
    end
  end

  private

  def create_rep_for(item, name)
    Nanoc::Int::ItemRep.new(item, name)
  end
end
