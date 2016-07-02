describe Nanoc::LayoutView do
  let(:entity_class) { Nanoc::Int::Layout }
  let(:other_view_class) { Nanoc::ItemWithRepsView }
  it_behaves_like 'a document view'
end
