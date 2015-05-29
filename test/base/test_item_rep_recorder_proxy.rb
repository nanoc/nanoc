class Nanoc::Int::ItemRepRecorderProxyTest < Nanoc::TestCase
  def test_double_names
    proxy = Nanoc::Int::ItemRepRecorderProxy.new(mock)

    proxy.snapshot(:foo, stuff: :giraffe)
    assert_raises(Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName) do
      proxy.snapshot(:foo, stuff: :donkey)
    end
  end

  def test_double_params
    proxy = Nanoc::Int::ItemRepRecorderProxy.new(mock)

    proxy.snapshot(:foo)
    proxy.snapshot(:bar)
  end
end
