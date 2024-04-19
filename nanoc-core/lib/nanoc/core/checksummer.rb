# frozen_string_literal: true

module Nanoc
  module Core
    # Creates checksums for given objects.
    #
    # A checksum is a string, such as “mL+TaqNsEeiPkWloPgCtAofT1yg=”, that is used
    # to determine whether a piece of data has changed.
    class Checksummer
      class VerboseDigest
        def initialize
          @str = +''
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
          obj.content_checksum_data || obj.checksum_data || Nanoc::Core::Checksummer.calc(obj.content)
        end

        def calc_for_each_attribute_of(obj, digest_class = CompactDigest)
          obj.attributes.transform_values do |value|
            Nanoc::Core::Checksummer.calc(value, digest_class)
          end
        end

        def define_behavior(klass, behavior)
          behaviors[klass] = behavior
        end

        private

        def update(obj, digest, visited = {})
          num = visited[obj]
          if num
            # If there already is an entry for this object, refer to it by its number.
            digest.update("@#{num}")
          else
            # This object isn’t known yet. Assign it a new number.
            num = visited.length
            visited[obj] = num

            digest.update(obj.class.to_s)
            digest.update("##{num}<")
            behavior_for(obj).update(obj, digest) { |o| update(o, digest, visited) }
            digest.update('>')
          end
        end

        def behaviors
          return @behaviors if @behaviors

          @behaviors = {}

          # NOTE: Other behaviors are registered elsewhere
          # (search for `define_behavior`).

          define_behavior(Array, CollectionUpdateBehavior)
          define_behavior(Set, SetUpdateBehavior)
          define_behavior(FalseClass, NoUpdateBehavior)
          define_behavior(Hash, HashUpdateBehavior)
          define_behavior(NilClass, NoUpdateBehavior)
          define_behavior(Numeric, RawUpdateBehavior)
          define_behavior(Pathname, PathnameUpdateBehavior)
          define_behavior(String, RawUpdateBehavior)
          define_behavior(Symbol, RawUpdateBehavior)
          define_behavior(Time, ToIToSUpdateBehavior)
          define_behavior(TrueClass, NoUpdateBehavior)

          define_behavior(Nanoc::Core::BinaryContent, BinaryContentUpdateBehavior)
          define_behavior(Nanoc::Core::Configuration, HashUpdateBehavior)
          define_behavior(Nanoc::Core::Context, ContextUpdateBehavior)
          define_behavior(Nanoc::Core::CodeSnippet, DataUpdateBehavior)
          define_behavior(Nanoc::Core::IdentifiableCollection, CollectionUpdateBehavior)
          define_behavior(Nanoc::Core::Identifier, ToSUpdateBehavior)
          define_behavior(Nanoc::Core::Item, DocumentUpdateBehavior)
          define_behavior(Nanoc::Core::ItemRep, ItemRepUpdateBehavior)
          define_behavior(Nanoc::Core::Layout, DocumentUpdateBehavior)
          define_behavior(Nanoc::Core::TextualContent, StringUpdateBehavior)
          define_behavior(Nanoc::Core::View, UnwrapUpdateBehavior)

          @behaviors
        end

        def behavior_for_class(klass)
          behaviors.fetch(klass) do
            if Object.equal?(klass.superclass)
              RescueUpdateBehavior
            else
              behavior_for_class(klass.superclass)
            end
          end
        end

        def behavior_for(obj)
          behavior_for_class(obj.class)
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
          yield(obj._unwrap)
        end
      end

      class CollectionUpdateBehavior < UpdateBehavior
        def self.update(obj, digest)
          obj.each do |el|
            yield(el)
            digest.update(',')
          end
        end
      end

      class SetUpdateBehavior < CollectionUpdateBehavior
        def self.update(obj, digest)
          # Similar to CollectionUpdateBehavior, but sorted for consistency.
          super(obj.sort { |a, b| (a <=> b) || 0 }, digest)
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
          # rubocop:disable Style/ClassEqualityComparison
          # This Rubocop rule is disabled because the class
          # itself might not be loaded (yet).
          if obj.class.to_s == 'Sass::Importers::Filesystem'
            digest.update('root=')
            digest.update(obj.root)
            return
          end
          # rubocop:enable Style/ClassEqualityComparison

          data =
            begin
              Marshal.dump(obj)
            rescue
              obj.inspect
            end

          digest.update(data)
        end
      end
    end
  end
end
