module Nanoc
  class PostCompileItemView < Nanoc::ItemView
    def modified
      reps.select { |rep| rep.modified }
    end
  end
end
