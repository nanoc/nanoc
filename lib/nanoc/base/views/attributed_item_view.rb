module Nanoc
  class AttributedItemView < Nanoc::ItemView
    def created?
      reps.select { |rep| rep.status == :created }
    end

    def updated?
      reps.select { |rep| rep.status == :modified }
    end
  end
end
