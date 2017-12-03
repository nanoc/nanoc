# frozen_string_literal: true

module Nanoc::Extra
  # @api private
  module PathnameExtensions
    def __nanoc_components
      components = []
      tmp = self
      loop do
        old = tmp
        components << File.basename(tmp)
        tmp = File.dirname(tmp)
        break if old == tmp
      end
      components.reverse
    end

    def __nanoc_include_component?(component)
      __nanoc_components.include?(component)
    end
  end
end

# @api private
class ::Pathname
  include ::Nanoc::Extra::PathnameExtensions
end
