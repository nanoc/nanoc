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
        digest.update('<')

        if visited.include?(obj)
          digest.update('recur>')
          return
        end

        case obj
        when ::String, ::Symbol, ::Numeric
          digest.update(obj.to_s)
        when nil, true, false
        when ::Array, ::Nanoc::Int::IdentifiableCollection
          obj.each do |el|
            update(el, digest, visited + [obj])
            digest.update(',')
          end
        when ::Hash, ::Nanoc::Int::Configuration
          obj.each do |key, value|
            update(key, digest, visited + [obj])
            digest.update('=')
            update(value, digest, visited + [obj])
            digest.update(',')
          end
        when ::Pathname
          filename = obj.to_s
          if File.exist?(filename)
            stat = File.stat(filename)
            digest.update(stat.size.to_s + '-' + stat.mtime.to_i.to_s)
          else
            digest.update('???')
          end
        when Time
          digest.update(obj.to_i.to_s)
        when Nanoc::Identifier
          update(obj.to_s, digest)
        when Nanoc::RuleDSL::RulesCollection, Nanoc::Int::CodeSnippet
          update(obj.data, digest)
        when Nanoc::Int::TextualContent
          update(obj.string, digest)
        when Nanoc::Int::BinaryContent
          update(Pathname.new(obj.filename), digest)
        when Nanoc::Int::Item, Nanoc::Int::Layout
          digest.update('content=')
          update(obj.content, digest)

          digest.update(',attributes=')
          update(obj.attributes, digest, visited + [obj])

          digest.update(',identifier=')
          update(obj.identifier, digest)
        when Nanoc::ItemView, Nanoc::LayoutView, Nanoc::ConfigView, Nanoc::IdentifiableCollectionView
          update(obj.unwrap, digest)
        else
          data = begin
            Marshal.dump(obj)
          rescue
            obj.inspect
          end

          digest.update(data)
        end

        digest.update('>')
      end
    end
  end
end
