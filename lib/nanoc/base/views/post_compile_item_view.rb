module Nanoc
  class PostCompileItemView < Nanoc::ItemWithRepsView
    def modified
      reps.select { |rep| rep.unwrap.modified }
    end
  end
end
