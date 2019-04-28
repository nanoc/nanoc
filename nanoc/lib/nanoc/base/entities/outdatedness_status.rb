# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class OutdatednessStatus
      attr_reader :reasons
      attr_reader :props

      def initialize(reasons: [], props: Nanoc::Core::DependencyProps.new)
        @reasons = reasons
        @props = props
      end

      def useful_to_apply?(rule)
        (rule.affected_props - @props.active).any?
      end

      def update(reason)
        self.class.new(
          reasons: @reasons + [reason],
          props: @props.merge(reason.props),
        )
      end
    end
  end
end
