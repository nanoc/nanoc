# encoding: utf-8

module Nanoc
end

require 'nanoc/base/core_ext'

# Load helper classes
require 'nanoc/base/context'
require 'nanoc/base/directed_graph'
require 'nanoc/base/errors'
require 'nanoc/base/memoization'
require 'nanoc/base/notification_center'
require 'nanoc/base/plugin_registry'
require 'nanoc/base/store'

# Load entity classes
require 'nanoc/base/entities/code_snippet'
require 'nanoc/base/entities/content'
require 'nanoc/base/entities/content_piece'
require 'nanoc/base/entities/configuration'
require 'nanoc/base/entities/data_source'
require 'nanoc/base/entities/item'
require 'nanoc/base/entities/item_array'
require 'nanoc/base/entities/item_rep'
require 'nanoc/base/entities/layout'
require 'nanoc/base/entities/identifier'
require 'nanoc/base/entities/site'

# Load store classes
require 'nanoc/base/stores/snapshot_store'

# Load compilation classes
require 'nanoc/base/compilation/checksum_store'
require 'nanoc/base/compilation/compiled_content_cache'
require 'nanoc/base/compilation/compiler'
require 'nanoc/base/compilation/compiler_dsl'
require 'nanoc/base/compilation/dependency_tracker'
require 'nanoc/base/compilation/filter'
require 'nanoc/base/compilation/item_rep_recorder_proxy'
require 'nanoc/base/compilation/item_rep_rules_proxy'
require 'nanoc/base/compilation/item_rep_writer'
require 'nanoc/base/compilation/outdatedness_checker'
require 'nanoc/base/compilation/outdatedness_reasons'
require 'nanoc/base/compilation/pattern'
require 'nanoc/base/compilation/rule'
require 'nanoc/base/compilation/rule_context'
require 'nanoc/base/compilation/rule_memory_calculator'
require 'nanoc/base/compilation/rule_memory_store'
require 'nanoc/base/compilation/rules_collection'
require 'nanoc/base/compilation/rules_store'

# Load stuff that should be loaded elsewhere
require 'nanoc/base/compilation/filesystem_rules_store'
