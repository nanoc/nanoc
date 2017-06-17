# frozen_string_literal: true

module Nanoc::Int
  # @api private
  module OutdatednessRules
  end
end

require_relative 'outdatedness_rules/attributes_modified'
require_relative 'outdatedness_rules/code_snippets_modified'
require_relative 'outdatedness_rules/content_modified'
require_relative 'outdatedness_rules/not_written'
require_relative 'outdatedness_rules/rules_modified'
require_relative 'outdatedness_rules/uses_always_outdated_filter'
