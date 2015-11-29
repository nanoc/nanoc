module Nanoc
  class PostCompileItemView < Nanoc::ItemView
    def modified
      reps.select(&:modified)
    end
  end
end
