# encoding: utf-8

class Nanoc::ItemRepRecorderProxyTest < Nanoc::TestCase
  def test_double_names
    proxy = Nanoc::ItemRepRecorderProxy.new(mock)

    proxy.snapshot(:foo, stuff: :giraffe)
    assert_raises(Nanoc::Errors::CannotCreateMultipleSnapshotsWithSameName) do
      proxy.snapshot(:foo, stuff: :donkey)
    end
  end

  def test_double_params
    proxy = Nanoc::ItemRepRecorderProxy.new(mock)

    proxy.snapshot(:foo)
    proxy.snapshot(:bar)
  end
end
