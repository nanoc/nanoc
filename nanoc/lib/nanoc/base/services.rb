# frozen_string_literal: true

require_relative 'services/compiler'
require_relative 'services/compiler_loader'
require_relative 'services/executor'
require_relative 'services/pruner'
require_relative 'services/outdatedness_rules'

require_relative 'services/compiler/phases'
require_relative 'services/compiler/stages'

require_relative 'services/outdatedness_checker'

# TODO: Move this into the entity, once the load order is improved (i.e. the
# checksummer is loaded after CodeSnippet).
Nanoc::Core::Checksummer.define_behavior(
  Nanoc::Core::CodeSnippet,
  Nanoc::Core::Checksummer::DataUpdateBehavior,
)
