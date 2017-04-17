module Nanoc::Int::OutdatednessRules
  class CodeSnippetsModified < Nanoc::Int::OutdatednessRule
    extend Nanoc::Int::Memoization

    include Nanoc::Int::ContractsSupport

    affects_props :raw_content, :attributes, :compiled_content, :path

    def apply(_obj, outdatedness_checker)
      if any_snippets_modified?(outdatedness_checker)
        Nanoc::Int::OutdatednessReasons::CodeSnippetsModified
      end
    end

    private

    memoized def any_snippets_modified?(outdatedness_checker)
      outdatedness_checker.site.code_snippets.any? do |cs|
        ch_old = outdatedness_checker.checksum_store[cs]
        ch_new = outdatedness_checker.checksums.checksum_for(cs)
        ch_old != ch_new
      end
    end
  end
end
