# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class BuildReps
    def initialize(site:, action_provider:, reps:)
      @site = site
      @action_provider = action_provider
      @reps = reps
    end

    def run
      # FIXME: This also, as a side effect, generates the action sequences. :(
      # Better: let this stage return a mapping of reps onto (raw) paths *and* a mapping of objects
      # onto action sequences.

      builder = Nanoc::Int::ItemRepBuilder.new(
        @site, @action_provider, @reps
      )

      action_sequences = builder.run

      @site.layouts.each do |layout|
        action_sequences[layout] = @action_provider.action_sequence_for(layout)
      end

      action_sequences
    end
  end
end
