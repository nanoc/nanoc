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

# Load source data classes
require 'nanoc/base/source_data/code_snippet'
require 'nanoc/base/source_data/configuration'
require 'nanoc/base/source_data/data_source'
require 'nanoc/base/source_data/item'
require 'nanoc/base/source_data/item_array'
require 'nanoc/base/source_data/layout'
require 'nanoc/base/source_data/site'

# Load result data classes
require 'nanoc/base/result_data/item_rep'
require 'nanoc/base/result_data/snapshot_store'

# Load compilation classes
require 'nanoc/base/compilation/checksum_store'
require 'nanoc/base/compilation/compiled_content_cache'
require 'nanoc/base/compilation/compiler'
require 'nanoc/base/compilation/compiler_dsl'
require 'nanoc/base/compilation/dependency_tracker'
require 'nanoc/base/compilation/filter'
require 'nanoc/base/compilation/item_rep_proxy'
require 'nanoc/base/compilation/item_rep_recorder_proxy'
require 'nanoc/base/compilation/item_rep_writer'
require 'nanoc/base/compilation/outdatedness_checker'
require 'nanoc/base/compilation/outdatedness_reasons'
require 'nanoc/base/compilation/rule'
require 'nanoc/base/compilation/rule_context'
require 'nanoc/base/compilation/rule_loader'
require 'nanoc/base/compilation/rule_memory_calculator'
require 'nanoc/base/compilation/rule_memory_store'
require 'nanoc/base/compilation/rules_collection'
