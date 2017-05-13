# frozen_string_literal: true

module Nanoc
  class PostCompileItemView < Nanoc::ItemWithRepsView
    def reps
      Nanoc::PostCompileItemRepCollectionView.new(@context.reps[unwrap], @context)
    end

    # @deprecated Use {#modified_reps} instead
    def modified
      modified_reps
    end

    def modified_reps
      reps.select { |rep| rep.unwrap.modified? }
    end
  end
end
