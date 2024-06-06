# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationStages
      class BuildReps < Nanoc::Core::CompilationStage
        include Nanoc::Core::ContractsSupport

        contract C::KeywordArgs[site: Nanoc::Core::Site, action_provider: Nanoc::Core::ActionProvider] => C::Any
        def initialize(site:, action_provider:)
          @site = site
          @action_provider = action_provider
        end

        def run
          reps = Nanoc::Core::ItemRepRepo.new

          builder = Nanoc::Core::ItemRepBuilder.new(
            @site, @action_provider, reps
          )

          action_sequences = builder.run

          @site.layouts.each do |layout|
            action_sequences[layout] = @action_provider.action_sequence_for(layout)
          end

          {
            reps:,
            action_sequences:,
          }
        end
      end
    end
  end
end
