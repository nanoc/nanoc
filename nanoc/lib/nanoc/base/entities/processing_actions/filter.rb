# frozen_string_literal: true

module Nanoc::Int::ProcessingActions
  class Filter < Nanoc::Int::ProcessingAction
    # filter :foo
    # filter :foo, params

    attr_reader :filter_name
    attr_reader :params

    def initialize(filter_name, params)
      @filter_name = filter_name
      @params      = params
    end

    def serialize
      [:filter, @filter_name, Nanoc::Int::Checksummer.calc(@params)]
    end

    def to_s
      "filter #{@filter_name.inspect}, #{@params.inspect}"
    end

    def hash
      self.class.hash ^ filter_name.hash ^ params.hash
    end

    def ==(other)
      self.class == other.class && filter_name == other.filter_name && params == other.params
    end

    def eql?(other)
      self == other
    end
  end
end
