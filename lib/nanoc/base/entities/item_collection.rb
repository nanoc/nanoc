# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class ItemCollection < IdentifiableCollection
    def initialize(config, objects = [])
      initialize_basic(config, objects, 'items')
    end
  end
end
