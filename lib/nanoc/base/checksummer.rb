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

    module Checksumming
      refine String do
        def update_digest(digest, checksummer, visited = Set.new)
          digest.update(self)
        end
      end

      refine Symbol do
        def update_digest(digest, checksummer, visited = Set.new)
          digest.update(self.to_s)
        end
      end

      refine NilClass do
        def update_digest(digest, checksummer, visited = Set.new)
        end
      end

      refine TrueClass do
        def update_digest(digest, checksummer, visited = Set.new)
        end
      end

      refine FalseClass do
        def update_digest(digest, checksummer, visited = Set.new)
        end
      end

      refine Array do
        def update_digest(digest, checksummer, visited = Set.new)
          each do |el|
            checksummer.update(el, digest, visited + [self])
            digest.update(',')
          end
        end
      end

      refine Hash do
        def update_digest(digest, checksummer, visited = Set.new)
          each do |key, value|
            checksummer.update(key, digest, visited + [self])
            digest.update('=')
            checksummer.update(value, digest, visited + [self])
            digest.update(',')
          end
        end
      end

      refine Nanoc::Int::Configuration do
        def update_digest(digest, checksummer, visited = Set.new)
          each do |key, value|
            checksummer.update(key, digest, visited + [self])
            digest.update('=')
            checksummer.update(value, digest, visited + [self])
            digest.update(',')
          end
        end
      end

      refine Pathname do
        def update_digest(digest, checksummer, visited = Set.new)
          filename = to_s
          if File.exist?(filename)
            stat = File.stat(filename)
            digest.update(stat.size.to_s + '-' + stat.mtime.to_i.to_s)
          else
            digest.update('???')
          end
        end
      end

      refine Time do
        def update_digest(digest, checksummer, visited = Set.new)
          digest.update(to_i.to_s)
        end
      end

      refine Numeric do
        def update_digest(digest, checksummer, visited = Set.new)
          digest.update(to_s)
        end
      end

      refine Nanoc::Identifier do
        def update_digest(digest, checksummer, visited = Set.new)
          checksummer.update(to_s, digest)
        end
      end

      refine Nanoc::Int::RulesCollection do
        def update_digest(digest, checksummer, visited = Set.new)
          checksummer.update(data, digest)
        end
      end

      refine Nanoc::Int::CodeSnippet do
        def update_digest(digest, checksummer, visited = Set.new)
          checksummer.update(data, digest)
        end
      end

      refine Nanoc::Int::TextualContent do
        def update_digest(digest, checksummer, visited = Set.new)
          checksummer.update(string, digest)
        end
      end

      refine Nanoc::Int::BinaryContent do
        def update_digest(digest, checksummer, visited = Set.new)
          checksummer.update(Pathname.new(filename), digest)
        end
      end

      refine Nanoc::Int::Document do
        def update_digest(digest, checksummer, visited = Set.new)
          digest.update('content=')
          checksummer.update(content, digest)

          digest.update(',attributes=')
          checksummer.update(attributes, digest, visited + [self])

          digest.update(',identifier=')
          checksummer.update(identifier, digest)
        end
      end

      refine Nanoc::Int::IdentifiableCollection do
        def update_digest(digest, checksummer, visited = Set.new)
          each do |el|
            checksummer.update(el, digest, visited + [self])
            digest.update(',')
          end
        end
      end

      [Nanoc::ItemView, Nanoc::LayoutView, Nanoc::ConfigView, Nanoc::IdentifiableCollectionView].each do |view_class|
        refine view_class do
          def update_digest(digest, checksummer, visited = Set.new)
            checksummer.update(unwrap, digest)
          end
        end
      end

      refine Object do
        def update_digest(digest, checksummer, visited = Set.new)
          data = begin
            Marshal.dump(self)
          rescue
            self.inspect
          end

          digest.update(data)
        end
      end
    end

    class << self
      using Checksumming

      # @param obj The object to create a checksum for
      #
      # @return [String] The digest
      def calc(obj, digest_class = CompactDigest)
        digest = digest_class.new
        update(obj, digest)
        digest.to_s
      end

      # @api private
      def update(obj, digest, visited = Set.new)
        digest.update(obj.class.to_s)
        digest.update('<')

        if visited.include?(obj)
          digest.update('recur>')
          return
        end

        obj.update_digest(digest, self, visited)

        digest.update('>')
      end
    end
  end
end
