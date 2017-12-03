# frozen_string_literal: true

module Nanoc
  class MutableIdentifiableCollectionView < Nanoc::IdentifiableCollectionView
    # Deletes every object for which the block evaluates to true.
    #
    # @yieldparam [#identifier] object
    #
    # @yieldreturn [Boolean]
    #
    # @return [self]
    def delete_if(&_block)
      @objects = @objects.reject { |o| yield(view_class.new(o, @context)) }
      self
    end
  end
end
