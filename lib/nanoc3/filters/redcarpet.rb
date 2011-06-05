# encoding: utf-8

module Nanoc3::Filters

  # @since 3.2.0
  class Redcarpet < Nanoc3::Filter

    # Runs the content through [Redcarpet](https://github.com/tanoku/redcarpet/).
    # This method optionally takes processing options to pass on to Redcarpet.
    #
    # @param [String] content The content to filter
    #
    # @option params [Array] :options ([]) A list of options to pass on to
    #   Redcarpet
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'redcarpet'

      options = params[:options] || []

      ::Redcarpet.new(content, *options).to_html
    end

  end

end
