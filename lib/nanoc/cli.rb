# Add Cri to load path
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../../vendor/cri/lib'))

# Load Cri
require 'cri'

# Module for CLI
module Nanoc::CLI # :nodoc:
end

# Load CLI
require 'nanoc/cli/logger'
require 'nanoc/cli/commands'
require 'nanoc/cli/base'
