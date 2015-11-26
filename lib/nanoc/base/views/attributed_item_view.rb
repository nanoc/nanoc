module Nanoc
  class AttributedItemView < Nanoc::ItemView
    include Nanoc::AttributedDocumentViewMixin

    def created?
      reps.select { |rep| rep.status == :created }
    end

    def updated?
      reps.select { |rep| rep.status == :modified }
    end
  end
end
