# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class OutdatednessStore < ::Nanoc::Int::Store
    include Nanoc::Core::ContractsSupport

    contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
    def initialize(config:)
      super(Nanoc::Int::Store.tmp_path_for(config: config, store_name: 'outdatedness'), 1)

      @outdated_refs = Set.new
    end

    contract Nanoc::Int::ItemRep => C::Bool
    def include?(obj)
      @outdated_refs.include?(obj.reference)
    end

    contract Nanoc::Int::ItemRep => self
    def add(obj)
      @outdated_refs << obj.reference
      self
    end

    contract Nanoc::Int::ItemRep => self
    def remove(obj)
      @outdated_refs.delete(obj.reference)
      self
    end

    contract C::None => C::Bool
    def empty?
      @outdated_refs.empty?
    end

    contract C::None => self
    def clear
      @outdated_refs = Set.new
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
