module Nanoc
  class PostCompileItemView < Nanoc::ItemWithRepsView
    # @deprecated Use {#modified_reps} instead
    def modified
      modified_reps
    end

    def modified_reps
      reps.select { |rep| rep.unwrap.modified? }
    end
  end
end
