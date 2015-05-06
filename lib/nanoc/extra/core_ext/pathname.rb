# encoding: utf-8

module Nanoc::Extra
  # @api private
  module PathnameExtensions
    def components
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

    def include_component?(component)
      components.include?(component)
    end
  end
end

class ::Pathname
  include ::Nanoc::Extra::PathnameExtensions
end
