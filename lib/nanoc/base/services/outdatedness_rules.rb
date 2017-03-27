module Nanoc::Int
  # @api private
  module OutdatednessRules
    class CodeSnippetsModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      include Nanoc::Int::ContractsSupport

      affects_props :raw_content, :attributes, :compiled_content, :path

      def apply(_obj, outdatedness_checker)
        if any_snippets_modified?(outdatedness_checker)
          Nanoc::Int::OutdatednessReasons::CodeSnippetsModified
        end
      end

      private

      def any_snippets_modified?(outdatedness_checker)
        outdatedness_checker.site.code_snippets.any? do |cs|
          ch_old = outdatedness_checker.checksum_store[cs]
          ch_new = Nanoc::Int::Checksummer.calc(cs)
          ch_old != ch_new
        end
      end
      memoize :any_snippets_modified?
    end

    class ConfigurationModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      affects_props :raw_content, :attributes, :compiled_content, :path

      def apply(_obj, outdatedness_checker)
        if config_modified?(outdatedness_checker)
          Nanoc::Int::OutdatednessReasons::ConfigurationModified
        end
      end

      private

      def config_modified?(outdatedness_checker)
        obj = outdatedness_checker.site.config
        ch_old = outdatedness_checker.checksum_store[obj]
        ch_new = Nanoc::Int::Checksummer.calc(obj)
        ch_old != ch_new
      end
      memoize :config_modified?
    end

    class NotWritten < OutdatednessRule
      affects_props :raw_content, :attributes, :compiled_content, :path

      def apply(obj, _outdatedness_checker)
        if obj.raw_paths.values.flatten.compact.any? { |fn| !File.file?(fn) }
          Nanoc::Int::OutdatednessReasons::NotWritten
        end
      end
    end

    class ContentModified < OutdatednessRule
      affects_props :raw_content, :compiled_content

      def apply(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)

        ch_old = outdatedness_checker.checksum_store.content_checksum_for(obj)
        ch_new = Nanoc::Int::Checksummer.calc_for_content_of(obj)
        if ch_old != ch_new
          Nanoc::Int::OutdatednessReasons::ContentModified
        end
      end
    end

    class AttributesModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      include Nanoc::Int::ContractsSupport

      affects_props :attributes, :compiled_content

      contract C::Or[Nanoc::Int::ItemRep, Nanoc::Int::Item, Nanoc::Int::Layout], C::Named['Nanoc::Int::OutdatednessChecker'] => C::Maybe[Nanoc::Int::OutdatednessReasons::Generic]
      def apply(obj, outdatedness_checker)
        case obj
        when Nanoc::Int::ItemRep
          apply(obj.item, outdatedness_checker)
        when Nanoc::Int::Item, Nanoc::Int::Layout
          ch_old = outdatedness_checker.checksum_store.attributes_checksum_for(obj)
          ch_new = Nanoc::Int::Checksummer.calc_for_attributes_of(obj)
          if ch_old != ch_new
            Nanoc::Int::OutdatednessReasons::AttributesModified
          end
        else
          raise ArgumentError
        end
      end
      memoize :apply
    end

    class RulesModified < OutdatednessRule
      affects_props :compiled_content, :path

      def apply(obj, outdatedness_checker)
        mem_old = outdatedness_checker.rule_memory_store[obj]
        mem_new = outdatedness_checker.action_provider.memory_for(obj).serialize
        unless mem_old.eql?(mem_new)
          Nanoc::Int::OutdatednessReasons::RulesModified
        end
      end
    end

    class PathsModified < OutdatednessRule
      affects_props :path

      def apply(obj, outdatedness_checker)
        # FIXME: Prefer to not work on serialised version

        mem_old = outdatedness_checker.rule_memory_store[obj]
        mem_new = outdatedness_checker.action_provider.memory_for(obj).serialize
        return true if mem_old.nil?

        paths_old = mem_old.select { |pa| pa[0] == :snapshot }
        paths_new = mem_new.select { |pa| pa[0] == :snapshot }

        if paths_old != paths_new
          Nanoc::Int::OutdatednessReasons::PathsModified
        end
      end
    end

    class UsesAlwaysOutdatedFilter < OutdatednessRule
      affects_props :raw_content, :attributes, :path

      def apply(obj, outdatedness_checker)
        mem = outdatedness_checker.action_provider.memory_for(obj)
        if any_always_outdated?(mem)
          Nanoc::Int::OutdatednessReasons::UsesAlwaysOutdatedFilter
        end
      end

      def any_always_outdated?(mem)
        mem
          .select { |a| a.is_a?(Nanoc::Int::ProcessingActions::Filter) }
          .map { |a| Nanoc::Filter.named(a.filter_name) }
          .compact
          .any?(&:always_outdated?)
      end
    end
  end
end
