# frozen_string_literal: true

module Nanoc
  module OrgMode
    class Filter < Nanoc::Filter
      identifier :org_mode

      # Runs the content through [Org Mode](https://orgmode.org/) via
      # [org-ruby](https://github.com/wallyqs/org-ruby).
      #
      # @param [String] content The content to filter
      #
      # @return [String] The filtered content
      def run(content, _params = {})
        ::Orgmode::Parser.new(content).to_html
      end
    end
  end
end
