# frozen_string_literal: true

module Nanoc
  module Core
    class PostCompileItemView < Nanoc::Core::CompilationItemView
      def reps
        Nanoc::Core::PostCompileItemRepCollectionView.new(@context.reps[_unwrap], @context)
      end

      # @deprecated Use {#modified_reps} instead
      def modified
        modified_reps
      end

      def modified_reps
        reps.select { |rep| rep._unwrap.modified? }
      end
    end
  end
end
