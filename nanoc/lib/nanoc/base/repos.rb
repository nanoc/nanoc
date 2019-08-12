# frozen_string_literal: true

# Re-exported from Nanoc::Core
Nanoc::DataSource = Nanoc::Core::DataSource

require_relative 'repos/config_loader'
require_relative 'repos/dependency_store'
require_relative 'repos/outdatedness_store'
require_relative 'repos/site_loader'
require_relative 'repos/compiled_content_store'
require_relative 'repos/prefixed_data_source'
