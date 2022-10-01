# frozen_string_literal: true

module Nanoc
  module Core
    module OutdatednessRules
      class NotWritten < Nanoc::Core::OutdatednessRule
        affects_props :raw_content, :attributes, :compiled_content, :path

        def apply(obj, outdatedness_checker)
          if obj.raw_paths.values.flatten.compact.any? { |fn| !exist?(fn, outdatedness_checker) }
            Nanoc::Core::OutdatednessReasons::NotWritten
          end
        end

        private

        def exist?(fn, outdatedness_checker)
          all(outdatedness_checker).include?(fn)
        end

        def all(outdatedness_checker)
          # NOTE: Cached per outdatedness checker, so that unrelated invocations
          # later on don’t reuse an old cache.

          @all ||= {}
          @all[outdatedness_checker] ||= Set.new(
            Dir.glob("#{site_root(outdatedness_checker)}/**/*", File::FNM_DOTMATCH),
          )
        end

        def site_root(outdatedness_checker)
          outdatedness_checker.site.config.output_dir
        end
      end
    end
  end
end
