module Nanoc::CLI # :nodoc:
end

# Load extensions
require 'nanoc/cli/ext'
require 'nanoc/cli/option_parser'

# Load logger
require 'nanoc/cli/logger'

# Load commands
require 'nanoc/cli/command'
require 'nanoc/cli/commands'

# Load base
require 'nanoc/cli/base'
