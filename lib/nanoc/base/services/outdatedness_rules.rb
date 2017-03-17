module Nanoc::Int
  # @api private
  module OutdatednessRules
    class CodeSnippetsModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      include Nanoc::Int::ContractsSupport

      def reason
        Nanoc::Int::OutdatednessReasons::CodeSnippetsModified
      end

      def apply(_obj, outdatedness_checker)
        any_snippets_modified?(outdatedness_checker)
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

      def reason
        Nanoc::Int::OutdatednessReasons::ConfigurationModified
      end

      def apply(_obj, outdatedness_checker)
        config_modified?(outdatedness_checker)
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
      def reason
        Nanoc::Int::OutdatednessReasons::NotWritten
      end

      def apply(obj, _outdatedness_checker)
        # FIXME: check all paths (for all snapshots)
        obj.raw_path && !File.file?(obj.raw_path)
      end
    end

    class ContentModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::ContentModified
      end

      def apply(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)

        ch_old = outdatedness_checker.checksum_store.content_checksum_for(obj)
        ch_new = Nanoc::Int::Checksummer.calc_for_content_of(obj)
        ch_old != ch_new
      end
    end

    class AttributesModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      include Nanoc::Int::ContractsSupport

      def reason
        Nanoc::Int::OutdatednessReasons::AttributesModified
      end

      contract C::Or[Nanoc::Int::ItemRep, Nanoc::Int::Item, Nanoc::Int::Layout], C::Named['Nanoc::Int::OutdatednessChecker'] => C::Bool
      def apply(obj, outdatedness_checker)
        case obj
        when Nanoc::Int::ItemRep
          apply(obj.item, outdatedness_checker)
        when Nanoc::Int::Item, Nanoc::Int::Layout
          ch_old = outdatedness_checker.checksum_store.attributes_checksum_for(obj)
          ch_new = Nanoc::Int::Checksummer.calc_for_attributes_of(obj)
          res = ch_old != ch_new
          res
        else
          raise ArgumentError
        end
      end
      memoize :apply
    end

    class RulesModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::RulesModified
      end

      def apply(obj, outdatedness_checker)
        mem_old = outdatedness_checker.rule_memory_store[obj]
        mem_new = outdatedness_checker.action_provider.memory_for(obj).serialize
        !mem_old.eql?(mem_new)
      end
    end

    class PathsModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::PathsModified
      end

      def apply(obj, outdatedness_checker)
        # FIXME: Prefer to not work on serialised version

        mem_old = outdatedness_checker.rule_memory_store[obj]
        mem_new = outdatedness_checker.action_provider.memory_for(obj).serialize
        return true if mem_old.nil?

        paths_old = mem_old.select { |pa| pa[0] == :snapshot }
        paths_new = mem_new.select { |pa| pa[0] == :snapshot }

        paths_old != paths_new
      end
    end

    class UsesAlwaysOutdatedFilter < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::UsesAlwaysOutdatedFilter
      end

      def apply(obj, outdatedness_checker)
        mem = outdatedness_checker.action_provider.memory_for(obj)

        mem
          .select { |a| a.is_a?(Nanoc::Int::ProcessingActions::Filter) }
          .map { |a| Nanoc::Filter.named(a.filter_name) }
          .compact
          .any?(&:always_outdated?)
      end
    end
  end
end
