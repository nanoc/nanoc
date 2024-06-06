# frozen_string_literal: true

module Nanoc
  module CLI
    # @api private
    module Transform
      module Port
        RANGE = (0x0001..0xffff)

        def self.call(data)
          Integer(data).tap do |int|
            raise 'not a valid port' unless RANGE.cover?(int)
          end
        end
      end
    end
  end
end
