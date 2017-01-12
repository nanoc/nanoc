describe Nanoc::Int::ItemRep do
  let(:item) { Nanoc::Int::Item.new('asdf', {}, '/foo.md') }
  let(:rep) { Nanoc::Int::ItemRep.new(item, :giraffe) }
end
