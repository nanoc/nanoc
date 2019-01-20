# frozen_string_literal: true

module Nanoc
  # @api private
  class ViewContextForCompilation
    include Nanoc::Core::ContractsSupport

    attr_reader :reps
    attr_reader :items
    attr_reader :dependency_tracker
    attr_reader :compilation_context
    attr_reader :compiled_content_store

    contract C::KeywordArgs[
      reps: Nanoc::Int::ItemRepRepo,
      items: Nanoc::Core::IdentifiableCollection,
      dependency_tracker: C::Any,
      compilation_context: C::Any,
      compiled_content_store: C::Any,
    ] => C::Any
    def initialize(reps:, items:, dependency_tracker:, compilation_context:, compiled_content_store:)
      @reps = reps
      @items = items
      @dependency_tracker = dependency_tracker
      @compilation_context = compilation_context
      @compiled_content_store = compiled_content_store
    end
  end
end
