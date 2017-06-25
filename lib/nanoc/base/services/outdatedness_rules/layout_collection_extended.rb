# frozen_string_literal: true

module Nanoc::Int::OutdatednessRules
  class LayoutCollectionExtended < Nanoc::Int::OutdatednessRule
    affects_props :raw_content

    contract Nanoc::Int::LayoutCollection, C::Named['Nanoc::Int::OutdatednessChecker'] => C::Maybe[Nanoc::Int::OutdatednessReasons::Generic]
    def apply(_obj, outdatedness_checker)
      if outdatedness_checker.dependency_store.any_new_objects?
        Nanoc::Int::OutdatednessReasons::LayoutCollectionExtended
      end
    end
  end
end
