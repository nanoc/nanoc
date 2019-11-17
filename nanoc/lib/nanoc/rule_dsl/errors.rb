# frozen_string_literal: true

module Nanoc
  module RuleDSL
    module Errors
      # Error that is raised when no rules file can be found in the current
      # working directory.
      class NoRulesFileFound < ::Nanoc::Core::Error
        def initialize
          super('This site does not have a rules file, which is required for Nanoc sites.')
        end
      end

      # Error that is raised when no compilation rule that can be applied to the
      # current item can be found.
      class NoMatchingCompilationRuleFound < ::Nanoc::Core::Error
        # @param [Nanoc::Core::Item] item The item for which no compilation rule
        #   could be found
        def initialize(item)
          super("No compilation rules were found for the “#{item.identifier}” item.")
        end
      end
    end
  end
end
