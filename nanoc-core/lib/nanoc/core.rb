# frozen_string_literal: true

require 'singleton'

module Nanoc
  # @api private
  module Core
  end
end

require 'nanoc/core/version'

require 'nanoc/core/contracts_support'
require 'nanoc/core/lazy_value'

require 'nanoc/core/core_ext/array'
require 'nanoc/core/core_ext/hash'
require 'nanoc/core/core_ext/string'

require 'nanoc/core/content'
require 'nanoc/core/textual_content'
require 'nanoc/core/binary_content'
