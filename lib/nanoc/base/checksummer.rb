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
        @str = ''
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

      private

      def update(obj, digest, visited = Set.new)
        digest.update(obj.class.to_s)

        if visited.include?(obj)
          digest.update('<recur>')
        else
          digest.update('<')
          behavior_for(obj).update(obj, digest) { |o| update(o, digest, visited + [obj]) }
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
      def self.update(_obj, _digest)
      end
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
          digest.update('content=')
          yield(obj.content)

          digest.update(',attributes=')
          yield(obj.attributes)

          digest.update(',identifier=')
          yield(obj.identifier)
        end
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
