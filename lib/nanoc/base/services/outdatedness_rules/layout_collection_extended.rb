# frozen_string_literal: true

module Nanoc::Int::OutdatednessRules
  class LayoutCollectionExtended < Nanoc::Int::OutdatednessRule
    affects_props :raw_content

    contract Nanoc::Int::LayoutCollection, C::Named['Nanoc::Int::OutdatednessChecker'] => C::Maybe[Nanoc::Int::OutdatednessReasons::Generic]
    def apply(_obj, outdatedness_checker)
      new_layouts = outdatedness_checker.dependency_store.new_layouts

      if new_layouts.any?
        Nanoc::Int::OutdatednessReasons::LayoutCollectionExtended.new(new_layouts)
      end
    end
  end
end
