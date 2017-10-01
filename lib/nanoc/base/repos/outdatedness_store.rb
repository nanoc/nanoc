# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class OutdatednessStore < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site]] => C::Any
    def initialize(site: nil)
      super(Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'outdatedness'), 1)

      @outdated_refs = Set.new
    end

    contract C::Or[String, Nanoc::Int::ItemRep] => C::Bool
    def include?(obj)
      case obj
      when String
        @outdated_refs.include?(obj)
      else
        @outdated_refs.include?(obj.reference)
      end
    end

    contract Nanoc::Int::ItemRep => self
    def add(obj)
      @outdated_refs << obj.reference

      self
    end

    contract Nanoc::Int::ItemRep => self
    def remove(obj)
      # TODO: clear all when completed
      @outdated_refs.delete(obj.reference)

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
