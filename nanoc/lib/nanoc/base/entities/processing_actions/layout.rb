# frozen_string_literal: true

module Nanoc::Int::ProcessingActions
  class Layout < Nanoc::Int::ProcessingAction
    # layout '/foo.erb'
    # layout '/foo.erb', params

    attr_reader :layout_identifier
    attr_reader :params

    def initialize(layout_identifier, params)
      @layout_identifier = layout_identifier
      @params = params
    end

    def serialize
      [:layout, @layout_identifier, Nanoc::Int::Checksummer.calc(@params)]
    end

    def to_s
      "layout #{@layout_identifier.inspect}, #{@params.inspect}"
    end

    def hash
      self.class.hash ^ layout_identifier.hash ^ params.hash
    end

    def ==(other)
      self.class == other.class && layout_identifier == other.layout_identifier && params == other.params
    end

    def eql?(other)
      self == other
    end
  end
end
