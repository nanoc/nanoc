# frozen_string_literal: true

module Nanoc
  module WithRepsViewMixin
    # Returns the compiled content.
    #
    # @param [String] rep The name of the representation
    #   from which the compiled content should be fetched. By default, the
    #   compiled content will be fetched from the default representation.
    #
    # @param [String] snapshot The name of the snapshot from which to
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The content of the given rep at the given snapshot.
    def compiled_content(rep: :default, snapshot: nil)
      reps.fetch(rep).compiled_content(snapshot: snapshot)
    end

    # Returns the item path, as used when being linked to. It starts
    # with a slash and it is relative to the output directory. It does not
    # include the path to the output directory. It will not include the
    # filename if the filename is an index filename.
    #
    # @param [String] rep The name of the representation
    #   from which the path should be fetched. By default, the path will be
    #   fetched from the default representation.
    #
    # @param [Symbol] snapshot The snapshot for which the
    #   path should be returned.
    #
    # @return [String] The item’s path.
    def path(rep: :default, snapshot: :last)
      reps.fetch(rep).path(snapshot: snapshot)
    end

    # Returns the representations of this item.
    #
    # @return [Nanoc::ItemRepCollectionView]
    def reps
      Nanoc::ItemRepCollectionView.new(@context.reps[unwrap], @context)
    end
  end
end
