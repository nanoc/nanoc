# frozen_string_literal: true

module Nanoc::Int::OutdatednessRules
  class NotWritten < Nanoc::Int::OutdatednessRule
    affects_props :raw_content, :attributes, :compiled_content, :path

    def apply(obj, _outdatedness_checker)
      if obj.raw_paths.values.flatten.compact.any? { |fn| !File.file?(fn) }
        Nanoc::Int::OutdatednessReasons::NotWritten
      end
    end
  end
end
