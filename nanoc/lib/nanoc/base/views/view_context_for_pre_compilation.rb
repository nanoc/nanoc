# frozen_string_literal: true

module Nanoc
  # @api private
  class ViewContextForPreCompilation
    include Nanoc::Core::ContractsSupport

    attr_reader :items
    attr_reader :dependency_tracker

    contract C::KeywordArgs[items: Nanoc::Core::IdentifiableCollection] => C::Any
    def initialize(items:)
      @items = items

      @dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
    end
  end
end
