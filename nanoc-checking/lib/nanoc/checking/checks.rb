# frozen_string_literal: true

# @api private
module Nanoc::Checking::Checks
end

require_relative 'checks/w3c_validator'

require_relative 'checks/css'
require_relative 'checks/external_links'
require_relative 'checks/html'
require_relative 'checks/internal_links'
require_relative 'checks/mixed_content'
require_relative 'checks/stale'
