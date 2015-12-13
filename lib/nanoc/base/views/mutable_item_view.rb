module Nanoc
  class MutableItemView < Nanoc::ItemWithoutRepsView
    include Nanoc::MutableDocumentViewMixin
  end
end
