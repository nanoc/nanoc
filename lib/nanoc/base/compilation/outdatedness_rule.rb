module Nanoc::Int
  class OutdatednessRule
    include Nanoc::Int::ContractsSupport
    include Singleton

    def apply(_obj, _outdatedness_checker)
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement ##reason, and #apply')
    end

    contract C::None => String
    def inspect
      "#{self.class.name}(#{reason})"
    end

    # TODO: remove
    def reason
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement ##reason, and #apply')
    end
  end

  module OutdatednessRules
    class CodeSnippetsModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      def reason
        Nanoc::Int::OutdatednessReasons::CodeSnippetsModified
      end

      def apply(_obj, outdatedness_checker)
        any_snippets_modified?(outdatedness_checker)
      end

      private

      def any_snippets_modified?(outdatedness_checker)
        outdatedness_checker.site.code_snippets.any? do |cs|
          outdatedness_checker.object_modified?(cs)
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
        outdatedness_checker.object_modified?(outdatedness_checker.site.config)
      end
      memoize :config_modified?
    end

    class NotWritten < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::NotWritten
      end

      def apply(obj, _outdatedness_checker)
        obj.raw_path && !File.file?(obj.raw_path)
      end
    end

    class NotEnoughData < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::NotEnoughData
      end

      def apply(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)
        !outdatedness_checker.checksums_available?(obj)
      end
    end

    class ContentModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::ContentModified
      end

      def apply(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)
        !outdatedness_checker.content_checksums_identical?(obj)
      end
    end

    class AttributesModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::AttributesModified
      end

      def apply(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)
        !outdatedness_checker.attributes_checksums_identical?(obj)
      end
    end

    class RulesModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::RulesModified
      end

      def apply(obj, outdatedness_checker)
        outdatedness_checker.rule_memory_differs_for(obj)
      end
    end
  end
end
