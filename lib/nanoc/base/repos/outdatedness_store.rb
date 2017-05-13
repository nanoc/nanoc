# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class OutdatednessStore < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site], reps: Nanoc::Int::ItemRepRepo] => C::Any
    def initialize(site: nil, reps:)
      super(Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'outdatedness'), 1)

      @outdated_reps = Set.new
      @all_reps = reps
    end

    contract Nanoc::Int::ItemRep => C::Bool
    def include?(obj)
      @outdated_reps.include?(obj)
    end

    contract Nanoc::Int::ItemRep => self
    def add(obj)
      @outdated_reps << obj
      self
    end

    contract Nanoc::Int::ItemRep => self
    def remove(obj)
      @outdated_reps.delete(obj)
      self
    end

    contract C::None => C::ArrayOf[Nanoc::Int::ItemRep]
    def to_a
      @outdated_reps.to_a
    end

    protected

    def data
      @outdated_reps.map(&:reference)
    end

    def data=(new_data)
      outdated_refs = Set.new(new_data)
      all_reps = Set.new(@all_reps)

      @outdated_reps = Set.new(all_reps.select { |rep| outdated_refs.include?(rep.reference) })
    end
  end
end
