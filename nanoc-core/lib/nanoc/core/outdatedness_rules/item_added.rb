# frozen_string_literal: true

module Nanoc
  module Core
    module OutdatednessRules
      class ItemAdded < Nanoc::Core::OutdatednessRule
        affects_props :raw_content

        contract Nanoc::Core::ItemRep, C::Named['Nanoc::Core::OutdatednessChecker'] => C::Maybe[Nanoc::Core::OutdatednessReasons::Generic]
        def apply(obj, outdatedness_checker)
          if outdatedness_checker.dependency_store.new_items.include?(obj.item)
            Nanoc::Core::OutdatednessReasons::DocumentAdded
          end
        end
      end
    end
  end
end
