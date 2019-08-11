# frozen_string_literal: true

module Nanoc
  module Int
    module OutdatednessRules
      class NotWritten < Nanoc::Core::OutdatednessRule
        affects_props :raw_content, :attributes, :compiled_content, :path

        def apply(obj, _outdatedness_checker)
          if obj.raw_paths.values.flatten.compact.any? { |fn| !File.file?(fn) }
            Nanoc::Core::OutdatednessReasons::NotWritten
          end
        end
      end
    end
  end
end
