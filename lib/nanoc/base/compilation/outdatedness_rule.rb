module Nanoc::Int
  class OutdatednessRule
    include Nanoc::Int::ContractsSupport
    include Singleton

    # TODO: add contract
    def pass?(_obj, _outdatedness_checker)
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement ##reason, and #pass?')
    end

    contract C::None => String
    def inspect
      s = "#{self.class.name}("
      s << (raw_content? ? 'r' : '_')
      s << (attributes? ? 'a' : '_')
      s << (compiled_content? ? 'c' : '_')
      s << (path? ? 'p' : '_')
      s << ')'
      s
    end

    def self.if_passing(obj, outdatedness_checker)
      yield(instance.reason) if instance.pass?(obj, outdatedness_checker)
    end

    # TODO: add contract
    # TODO: remove
    def reason
      raise NotImplementedError.new('Nanoc::Int::OutdatednessRule subclasses must implement ##reason, and #pass?')
    end

    contract C::None => C::Bool
    def all?
      false
    end

    contract C::None => C::Bool
    def raw_content?
      false
    end

    contract C::None => C::Bool
    def attributes?
      false
    end

    contract C::None => C::Bool
    def compiled_content?
      false
    end

    contract C::None => C::Bool
    def path?
      false
    end
  end

  module OutdatednessRules
    class CodeSnippetsModified < OutdatednessRule
      extend Nanoc::Int::Memoization

      def reason
        Nanoc::Int::OutdatednessReasons::CodeSnippetsModified
      end

      def pass?(_obj, outdatedness_checker)
        any_snippets_modified?(outdatedness_checker)
      end

      def all?
        true
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

      def pass?(_obj, outdatedness_checker)
        config_modified?(outdatedness_checker)
      end

      def all?
        true
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

      def pass?(obj, _outdatedness_checker)
        obj.raw_path && !File.file?(obj.raw_path)
      end

      def all?
        true
      end
    end

    class NotEnoughData < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::NotEnoughData
      end

      def pass?(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)
        !outdatedness_checker.checksums_available?(obj)
      end

      def all?
        true
      end
    end

    class ContentModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::ContentModified
      end

      def pass?(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)
        !outdatedness_checker.content_checksums_identical?(obj)
      end

      def all?
        true
      end
    end

    class AttributesModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::AttributesModified
      end

      def pass?(obj, outdatedness_checker)
        obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)
        !outdatedness_checker.attributes_checksums_identical?(obj)
      end

      def all?
        true
      end
    end

    class RulesModified < OutdatednessRule
      def reason
        Nanoc::Int::OutdatednessReasons::RulesModified
      end

      def pass?(obj, outdatedness_checker)
        outdatedness_checker.rule_memory_differs_for(obj)
      end

      def all?
        true
      end
    end
  end
end
