# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#breadcrumbs
  module Breadcrumbs
    # @api private
    module Int
      # e.g. unfold(10.class, &:superclass)
      # => [Integer, Numeric, Object, BasicObject]
      def self.unfold(obj, &blk)
        acc = [obj]

        res = yield(obj)
        if res
          acc + unfold(res, &blk)
        else
          acc
        end
      end

      # e.g. patterns_for_prefix('/foo/1.0')
      # => ['/foo/1.0.*', '/foo/1.*']
      def self.patterns_for_prefix(prefix)
        prefixes =
          unfold(prefix) do |old_prefix|
            new_prefix = Nanoc::Identifier.new(old_prefix).without_ext
            new_prefix == old_prefix ? nil : new_prefix
          end

        prefixes.map { |pr| pr + '.*' }
      end
    end

    # @return [Array]
    def breadcrumbs_trail
      # e.g. ['', '/foo', '/foo/bar']
      components = item.identifier.components
      prefixes = components.inject(['']) { |acc, elem| acc + [acc.last + '/' + elem] }

      if @item.identifier.legacy?
        prefixes.map { |pr| @items[Nanoc::Identifier.new('/' + pr, type: :legacy)] }
      else
        prefixes
          .reject { |pr| pr =~ /^\/index\./ }
          .map do |pr|
            if pr == ''
              @items['/index.*']
            else
              prefix_patterns = Int.patterns_for_prefix(pr)
              prefix_patterns.lazy.map { |pat| @items[pat] }.find(&:itself)
            end
          end
      end
    end
  end
end
