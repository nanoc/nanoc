# frozen_string_literal: true

module Nanoc
  module Core
    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # @api private
    class TextualCompiledContentCache < ::Nanoc::Core::Store
      include Nanoc::Core::ContractsSupport

      class LazyCompressedValue
        def initialize(uncompressed: nil, compressed: nil)
          if uncompressed.nil? && compressed.nil?
            raise ArgumentError, 'must specify at least uncompressed or compressed'
          end

          @_uncompressed = uncompressed
          @_compressed = compressed
        end

        def compressed
          @_compressed ||= Zlib::Deflate.deflate(Marshal.dump(@_uncompressed), Zlib::BEST_SPEED)
        end

        def uncompressed
          @_uncompressed ||= Marshal.load(Zlib::Inflate.inflate(@_compressed))
        end

        def marshal_dump
          [compressed]
        end

        def marshal_load(array)
          @_compressed = array[0]
          @_uncompressed = nil
        end
      end

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        super(
          self.class.tmp_path_for(
            config:,
            store_name: 'compiled_content',
          ),
          5,
        )

        @cache = {}
      end

      contract Nanoc::Core::ItemRep =>
        C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      # Returns the cached compiled content for the given item representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names, and the values the compiled content at the given snapshot.
      def [](rep)
        item_cache = @cache[rep.item.identifier] || {}
        item_cache[rep.name]&.uncompressed
      end

      contract Nanoc::Core::ItemRep => C::Bool
      def include?(rep)
        item_cache = @cache[rep.item.identifier] || {}
        item_cache.key?(rep.name)
      end

      contract Nanoc::Core::ItemRep,
               C::HashOf[Symbol => Nanoc::Core::TextualContent] => C::Any
      # Sets the compiled content for the given representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names, and the values the compiled content at the given snapshot.
      def []=(rep, content)
        @cache[rep.item.identifier] ||= {}
        @cache[rep.item.identifier][rep.name] = LazyCompressedValue.new(uncompressed: content)
      end

      def prune(items:)
        item_identifiers = Set.new(items.map(&:identifier))

        @cache.each_key do |key|
          # TODO: remove unused item reps
          next if item_identifiers.include?(key)

          @cache.delete(key)
        end
      end

      # Similar to Store#load_data, but does not use zlib compression on the
      # data itself (instead, values are compressed individually).
      def load_data
        raw_data = File.binread(data_filename)
        self.data = Marshal.load(raw_data)
      end

      # Similar to Store#store_data, but does not use zlib compression on the
      # data itself (instead, values are compressed individually).
      def store_data
        raw_data = Marshal.dump(data)
        write_data_to_file(data_filename, raw_data)
      end

      # Identical to Store#store_data; replicated for clarity.
      def reset_data
        FileUtils.rm_f(data_filename)
      end

      protected

      def data
        @cache
      end

      def data=(new_data)
        @cache = {}

        new_data.each_pair do |item_identifier, content_per_rep|
          @cache[item_identifier] ||= content_per_rep
        end
      end
    end
  end
end
