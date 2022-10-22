# frozen_string_literal: true

module Nanoc
  module Core
    module OutdatednessRules
      class CodeSnippetsModified < Nanoc::Core::OutdatednessRule
        prepend MemoWise

        # include Nanoc::Core::ContractsSupport

        affects_props :raw_content, :attributes, :compiled_content, :path

        def apply(_obj, basic_outdatedness_checker)
          if any_snippets_modified?(basic_outdatedness_checker)
            Nanoc::Core::OutdatednessReasons::CodeSnippetsModified
          end
        end

        private

        def any_snippets_modified?(basic_outdatedness_checker)
          basic_outdatedness_checker.site.code_snippets.any? do |cs|
            ch_old = basic_outdatedness_checker.checksum_store[cs]
            ch_new = basic_outdatedness_checker.checksums.checksum_for(cs)
            ch_old != ch_new
          end
        end
        memo_wise :any_snippets_modified?
      end
    end
  end
end
