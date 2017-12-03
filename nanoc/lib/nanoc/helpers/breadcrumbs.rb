# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#breadcrumbs
  module Breadcrumbs
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
              @items[Nanoc::Identifier.new(pr).without_ext + '.*']
            end
          end
      end
    end
  end
end
