module Nanoc::Int
  # @api private
  class OutdatednessStore < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site]] => C::Any
    def initialize(site: nil)
      super(Nanoc::Int::Store.tmp_path_for(env_name: (site.config.env_name if site), store_name: 'outdatedness'), 1)

      @refs = Set.new
    end

    contract Nanoc::Int::ItemRep => C::Bool
    def include?(obj)
      @refs.include?(obj.reference)
    end

    contract Nanoc::Int::ItemRep => self
    def add(obj)
      @refs << obj.reference
      self
    end

    contract Nanoc::Int::ItemRep => self
    def remove(obj)
      @refs.delete(obj.reference)
      self
    end

    protected

    def data
      @refs
    end

    def data=(new_data)
      # FIXME: remove strings for which no object exists
      @refs = new_data
    end
  end
end
