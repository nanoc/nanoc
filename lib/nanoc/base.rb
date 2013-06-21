# encoding: utf-8

module Nanoc
end

require 'nanoc/base/core_ext'
require 'nanoc/base/errors'

# Load helper classes
require 'nanoc/base/helper/context'
require 'nanoc/base/helper/directed_graph'
require 'nanoc/base/helper/memoization'
require 'nanoc/base/helper/notification_center'
require 'nanoc/base/helper/plugin_registry'

# Load entity classes
require 'nanoc/base/entities/code_snippet'
require 'nanoc/base/entities/content'
require 'nanoc/base/entities/configuration'
require 'nanoc/base/entities/document'
require 'nanoc/base/entities/item'
require 'nanoc/base/entities/item_array'
require 'nanoc/base/entities/item_rep'
require 'nanoc/base/entities/layout'
require 'nanoc/base/entities/identifier'
require 'nanoc/base/entities/pattern'
require 'nanoc/base/entities/site'

# Load proxy classes
require 'nanoc/base/proxies/item_proxy'

# Load store classes
require 'nanoc/base/store'
require 'nanoc/base/stores/data_source'
require 'nanoc/base/stores/snapshot_store'
require 'nanoc/base/stores/rules_store'
require 'nanoc/base/stores/filesystem_rules_store'
require 'nanoc/base/stores/checksum_store'
require 'nanoc/base/stores/compiled_content_cache'
require 'nanoc/base/stores/rule_memory_store'
require 'nanoc/base/stores/item_rep_writer'
require 'nanoc/base/stores/item_rep_store'

# Load interactor classes
require 'nanoc/base/interactors/site_loader'

# Load compilation classes
require 'nanoc/base/compilation/compiler'
require 'nanoc/base/compilation/compiler_dsl'
require 'nanoc/base/compilation/dependency_tracker'
require 'nanoc/base/compilation/filter'
require 'nanoc/base/compilation/item_rep_recorder_proxy'
require 'nanoc/base/compilation/item_rep_rules_proxy'
require 'nanoc/base/compilation/outdatedness_checker'
require 'nanoc/base/compilation/outdatedness_reasons'
require 'nanoc/base/compilation/rule'
require 'nanoc/base/compilation/rule_context'
require 'nanoc/base/compilation/rule_memory_calculator'
require 'nanoc/base/compilation/rules_collection'
