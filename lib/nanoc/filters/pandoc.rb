# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Pandoc < Nanoc::Filter
    identifier :pandoc

    requires 'pandoc-ruby'

    # Runs the content through [Pandoc](http://johnmacfarlane.net/pandoc/)
    # using [PandocRuby](https://github.com/alphabetum/pandoc-ruby).
    #
    # Arguments can be passed to PandocRuby in two ways:
    #
    # * Use the `:args` option. This approach is more flexible, since it
    #   allows passing an array instead of a hash.
    #
    # * Pass the arguments directly to the filter. With this approach, only
    #   hashes can be passed, which is more limiting than the `:args` approach.
    #
    # The `:args` approach is recommended.
    #
    # @example Passing arguments using `:arg`
    #
    #     filter :pandoc, args: [:s, {:f => :markdown, :to => :html}, 'no-wrap', :toc]
    #
    # @example Passing arguments not using `:arg`
    #
    #     filter :pandoc, :f => :markdown, :to => :html
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      args = params.key?(:args) ? params[:args] : params

      PandocRuby.convert(content, *args)
    end
  end
end
