# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class OutdatednessStore < ::Nanoc::Int::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        super(Nanoc::Int::Store.tmp_path_for(config: config, store_name: 'outdatedness'), 1)

        @mutex = Mutex.new
        @outdated_refs = Set.new
      end

      contract Nanoc::Core::ItemRep => C::Bool
      def include?(obj)
        @mutex.synchronize do
          @outdated_refs.include?(obj.reference)
        end
      end

      contract Nanoc::Core::ItemRep => self
      def add(obj)
        @mutex.synchronize do
          @outdated_refs << obj.reference
        end
        self
      end

      contract Nanoc::Core::ItemRep => self
      def remove(obj)
        @mutex.synchronize do
          @outdated_refs.delete(obj.reference)
        end
        self
      end

      contract C::None => C::Bool
      def empty?
        @mutex.synchronize do
          @outdated_refs.empty?
        end
      end

      contract C::None => self
      def clear
        @mutex.synchronize do
          @outdated_refs = Set.new
        end
        self
      end

      protected

      def data
        @outdated_refs
      end

      def data=(new_data)
        @outdated_refs = Set.new(new_data)
      end
    end
  end
end
