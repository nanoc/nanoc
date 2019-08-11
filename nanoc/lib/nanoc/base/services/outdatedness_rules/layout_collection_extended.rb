# frozen_string_literal: true

module Nanoc
  module Int
    module OutdatednessRules
      class LayoutCollectionExtended < Nanoc::Core::OutdatednessRule
        affects_props :raw_content

        contract Nanoc::Core::LayoutCollection, C::Named['Nanoc::Int::OutdatednessChecker'] => C::Maybe[Nanoc::Core::OutdatednessReasons::Generic]
        def apply(_obj, outdatedness_checker)
          new_layouts = outdatedness_checker.dependency_store.new_layouts

          if new_layouts.any?
            Nanoc::Core::OutdatednessReasons::LayoutCollectionExtended.new(new_layouts)
          end
        end
      end
    end
  end
end
