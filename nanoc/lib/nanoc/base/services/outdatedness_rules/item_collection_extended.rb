# frozen_string_literal: true

module Nanoc::Int::OutdatednessRules
  class ItemCollectionExtended < Nanoc::Int::OutdatednessRule
    affects_props :raw_content

    contract Nanoc::Int::ItemCollection, C::Named['Nanoc::Int::OutdatednessChecker'] => C::Maybe[Nanoc::Int::OutdatednessReasons::Generic]
    def apply(_obj, outdatedness_checker)
      new_items = outdatedness_checker.dependency_store.new_items

      if new_items.any?
        Nanoc::Int::OutdatednessReasons::ItemCollectionExtended.new(new_items)
      end
    end
  end
end
