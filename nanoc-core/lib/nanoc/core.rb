# frozen_string_literal: true

# Ruby stdlib
require 'singleton'

# External gems
require 'json_schema'
require 'ddmemoize'
require 'ddmetrics'

DDMemoize.enable_metrics

module Nanoc
  # @api private
  module Core
  end
end

require 'nanoc/core/version'

require 'nanoc/core/contracts_support'
require 'nanoc/core/lazy_value'
require 'nanoc/core/error'

require 'nanoc/core/configuration'
require 'nanoc/core/content'
require 'nanoc/core/context'
require 'nanoc/core/directed_graph'
require 'nanoc/core/pattern'
require 'nanoc/core/identifiable_collection'
require 'nanoc/core/identifier'
require 'nanoc/core/core_ext/array'
require 'nanoc/core/core_ext/hash'
require 'nanoc/core/core_ext/string'

require 'nanoc/core/binary_content'
require 'nanoc/core/item_collection'
require 'nanoc/core/layout_collection'
require 'nanoc/core/regexp_pattern'
require 'nanoc/core/string_pattern'
require 'nanoc/core/textual_content'

require 'nanoc/core/document'
require 'nanoc/core/item'
require 'nanoc/core/layout'
