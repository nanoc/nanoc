# frozen_string_literal: true

module Nanoc::Int
  # Creates checksums for given objects.
  #
  # A checksum is a string, such as “mL+TaqNsEeiPkWloPgCtAofT1yg=”, that is used
  # to determine whether a piece of data has changed.
  #
  # @api private
  class Checksummer
    class VerboseDigest
      def initialize
        @str = String.new
      end

      def update(str)
        @str << str
      end

      def to_s
        @str
      end
    end

    class CompactDigest
      def initialize
        @digest = Digest::SHA1.new
      end

      def update(str)
        @digest.update(str)
      end

      def to_s
        @digest.base64digest
      end
    end

    class << self
      # @param obj The object to create a checksum for
      #
      # @return [String] The digest
      def calc(obj, digest_class = CompactDigest)
        digest = digest_class.new
        update(obj, digest)
        digest.to_s
      end

      def calc_for_content_of(obj)
        obj.content_checksum_data || obj.checksum_data || Nanoc::Int::Checksummer.calc(obj.content)
      end

      def calc_for_each_attribute_of(obj, digest_class = CompactDigest)
        obj.attributes.each_with_object({}) do |(key, value), memo|
          memo[key] = Nanoc::Int::Checksummer.calc(value, digest_class)
        end
      end

      private

      def update(obj, digest, visited = Hamster::Set.new)
        digest.update(obj.class.to_s)

        if visited.include?(obj)
          digest.update('<recur>')
        else
          digest.update('<')
          behavior_for(obj).update(obj, digest) { |o| update(o, digest, visited.add(obj)) }
          digest.update('>')
        end
      end

      def behavior_for(obj)
        case obj
        when String, Symbol, Numeric
          RawUpdateBehavior
        when Pathname
          PathnameUpdateBehavior
        when Nanoc::Int::BinaryContent
          BinaryContentUpdateBehavior
        when Array, Nanoc::Int::IdentifiableCollection
          ArrayUpdateBehavior
        when Hash, Nanoc::Int::Configuration
          HashUpdateBehavior
        when Nanoc::Int::Item, Nanoc::Int::Layout
          DocumentUpdateBehavior
        when Nanoc::Int::ItemRep
          ItemRepUpdateBehavior
        when NilClass, TrueClass, FalseClass
          NoUpdateBehavior
        when Time
          ToIToSUpdateBehavior
        when Nanoc::Identifier
          ToSUpdateBehavior
        when Nanoc::RuleDSL::RulesCollection, Nanoc::Int::CodeSnippet
          DataUpdateBehavior
        when Nanoc::Int::TextualContent
          StringUpdateBehavior
        when Nanoc::View
          UnwrapUpdateBehavior
        when Nanoc::RuleDSL::RuleContext
          RuleContextUpdateBehavior
        when Nanoc::Int::Context
          ContextUpdateBehavior
        else
          RescueUpdateBehavior
        end
      end
    end

    class UpdateBehavior
      def self.update(_obj, _digest)
        raise NotImpementedError
      end
    end

    class RuleContextUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        digest.update('item=')
        yield(obj.item)
        digest.update(',rep=')
        yield(obj.rep)
        digest.update(',items=')
        yield(obj.items)
        digest.update(',layouts=')
        yield(obj.layouts)
        digest.update(',config=')
        yield(obj.config)
      end
    end

    class ContextUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        obj.instance_variables.each do |var|
          digest.update(var.to_s)
          digest.update('=')
          yield(obj.instance_variable_get(var))
          digest.update(',')
        end
      end
    end

    class RawUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        digest.update(obj.to_s)
      end
    end

    class ToSUpdateBehavior < UpdateBehavior
      def self.update(obj, _digest)
        yield(obj.to_s)
      end
    end

    class ToIToSUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        digest.update(obj.to_i.to_s)
      end
    end

    class StringUpdateBehavior < UpdateBehavior
      def self.update(obj, _digest)
        yield(obj.string)
      end
    end

    class DataUpdateBehavior < UpdateBehavior
      def self.update(obj, _digest)
        yield(obj.data)
      end
    end

    class NoUpdateBehavior < UpdateBehavior
      def self.update(_obj, _digest); end
    end

    class UnwrapUpdateBehavior < UpdateBehavior
      def self.update(obj, _digest)
        yield(obj.unwrap)
      end
    end

    class ArrayUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        obj.each do |el|
          yield(el)
          digest.update(',')
        end
      end
    end

    class HashUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        obj.each do |key, value|
          yield(key)
          digest.update('=')
          yield(value)
          digest.update(',')
        end
      end
    end

    class DocumentUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        if obj.checksum_data
          digest.update('checksum_data=' + obj.checksum_data)
        else
          if obj.content_checksum_data
            digest.update('content_checksum_data=' + obj.content_checksum_data)
          else
            digest.update('content=')
            yield(obj.content)
          end

          if obj.attributes_checksum_data
            digest.update(',attributes_checksum_data=' + obj.attributes_checksum_data)
          else
            digest.update(',attributes=')
            yield(obj.attributes)
          end

          digest.update(',identifier=')
          yield(obj.identifier)
        end
      end
    end

    class ItemRepUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        digest.update('item=')
        yield(obj.item)
        digest.update(',name=')
        yield(obj.name)
      end
    end

    class PathnameUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        filename = obj.to_s
        if File.exist?(filename)
          stat = File.stat(filename)
          digest.update(stat.size.to_s + '-' + stat.mtime.to_i.to_s)
        else
          digest.update('???')
        end
      end
    end

    class BinaryContentUpdateBehavior < UpdateBehavior
      def self.update(obj, _digest)
        yield(Pathname.new(obj.filename))
      end
    end

    class RescueUpdateBehavior < UpdateBehavior
      def self.update(obj, digest)
        if obj.class.to_s == 'Sass::Importers::Filesystem'
          digest.update('root=')
          digest.update(obj.root)
          return
        end

        data = begin
          Marshal.dump(obj)
        rescue
          obj.inspect
        end

        digest.update(data)
      end
    end
  end
end
