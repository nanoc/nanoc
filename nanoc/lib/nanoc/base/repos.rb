# frozen_string_literal: true

# Re-exported from Nanoc::Core
Nanoc::DataSource = Nanoc::Core::DataSource

require_relative 'repos/store'

require_relative 'repos/checksum_store'
require_relative 'repos/compiled_content_cache'
require_relative 'repos/config_loader'
require_relative 'repos/dependency_store'
require_relative 'repos/item_rep_repo'
require_relative 'repos/outdatedness_store'
require_relative 'repos/action_sequence_store'
require_relative 'repos/site_loader'
require_relative 'repos/compiled_content_store'
require_relative 'repos/in_mem_data_source'
require_relative 'repos/aggregate_data_source'
require_relative 'repos/prefixed_data_source'
