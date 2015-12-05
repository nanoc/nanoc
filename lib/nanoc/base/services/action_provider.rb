module Nanoc::Int
  # @private
  class ActionProvider
    def rep_names_for(_item)
      raise NotImplementedError
    end

    def memory_for(_rep)
      raise NotImplementedError
    end

    def snapshots_defs_for(_rep)
      raise NotImplementedError
    end
  end
end
