# encoding: utf-8

module Nanoc
  class MutableIdentifiableCollectionView < Nanoc::IdentifiableCollectionView
    # Deletes every object for which the block evaluates to true.
    #
    # @yieldparam object
    #
    # @yieldreturn [Boolean]
    #
    # @return [self]
    def delete_if(&block)
      @objects.delete_if { |o| yield(view_class.new(o)) }
      self
    end
  end
end
