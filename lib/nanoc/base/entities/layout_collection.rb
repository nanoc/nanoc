# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class LayoutCollection < IdentifiableCollection
    def initialize(config, objects = [])
      initialize_basic(config, objects, 'layouts')
    end
  end
end
