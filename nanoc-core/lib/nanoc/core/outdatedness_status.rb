# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class OutdatednessStatus
      attr_reader :reasons
      attr_reader :props

      def initialize(reasons: [], props: Nanoc::Core::DependencyProps.new)
        @reasons = reasons
        @props = props
      end

      def useful_to_apply?(rule)
        return true if rule.affects_raw_content? && !@props.raw_content?
        return true if rule.affects_attributes? && !@props.attributes?
        return true if rule.affects_compiled_content? && !@props.compiled_content?
        return true if rule.affects_path? && !@props.path?

        false
      end

      def update(reason)
        self.class.new(
          reasons: @reasons + [reason],
          props: @props.merge(reason.props),
        )
      end

      def inspect
        "<#{self.class} reasons=#{@reasons.inspect} props=#{@props.inspect}>"
      end
    end
  end
end
