# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class OrgMode < Nanoc::Filter
    identifier :orgmode

    requires 'org-ruby'
    # Runs the content through [org-ruby](https://github.com/wallyqs/org-ruby).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      ::Orgmode::Parser.new(content).to_html
    end
  end
end
