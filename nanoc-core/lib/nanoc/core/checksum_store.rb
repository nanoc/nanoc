# frozen_string_literal: true

module Nanoc
  module Core
    # Stores checksums for objects in order to be able to detect whether a file
    # has changed since the last site compilation.
    #
    # @api private
    class ChecksumStore < ::Nanoc::Core::Store
      include Nanoc::Core::ContractsSupport

      attr_writer :checksums
      attr_accessor :objects

      c_obj = C::Or[Nanoc::Core::Item, Nanoc::Core::Layout, Nanoc::Core::Configuration, Nanoc::Core::CodeSnippet]

      contract C::KeywordArgs[config: Nanoc::Core::Configuration, objects: C::IterOf[c_obj]] => C::Any
      def initialize(config:, objects:)
        super(Nanoc::Core::Store.tmp_path_for(config:, store_name: 'checksums'), 3)

        @objects = objects

        @checksums = {}

        invalidate_memoization
      end

      contract c_obj => C::Maybe[String]
      def [](obj)
        @checksums[obj.reference]
      end

      contract c_obj => self
      def add(obj)
        if obj.is_a?(Nanoc::Core::Document)
          @checksums[[obj.reference, :content]] = Nanoc::Core::Checksummer.calc_for_content_of(obj)
        end

        if obj.is_a?(Nanoc::Core::Document) || obj.is_a?(Nanoc::Core::Configuration)
          @checksums[[obj.reference, :each_attribute]] = Nanoc::Core::Checksummer.calc_for_each_attribute_of(obj)
        end

        @checksums[obj.reference] = Nanoc::Core::Checksummer.calc(obj)

        self
      end

      contract c_obj => C::Maybe[String]
      def content_checksum_for(obj)
        @checksums[[obj.reference, :content]]
      end

      contract c_obj => C::Maybe[C::HashOf[Symbol, String]]
      def attributes_checksum_for(obj)
        @_attribute_checksums[obj] ||= @checksums[[obj.reference, :each_attribute]]
      end

      protected

      def data
        @checksums
      end

      def data=(new_data)
        invalidate_memoization

        references = Set.new(@objects.map(&:reference))

        @checksums = {}
        new_data.each_pair do |key, checksum|
          if references.include?(key) || (key.respond_to?(:first) && references.include?(key.first))
            @checksums[key] = checksum
          end
        end
      end

      private

      def invalidate_memoization
        @_attribute_checksums = {}
      end
    end
  end
end
