module Nanoc
  class PostCompileItemView < Nanoc::ItemView
    def modified
      reps.select { |rep| rep.unwrap.modified }
    end
  end
end
