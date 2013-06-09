# encoding: utf-8

module Nanoc

  class ItemRepStore

    attr_reader :reps

    def initialize(reps)
      @reps = reps
    end

    def reps_by_item
      @_reps_by_item ||= @reps.group_by { |r| r.item }
    end

    def reps_for_item(item)
      self.reps_by_item.fetch(item, [])
    end

  end

end
