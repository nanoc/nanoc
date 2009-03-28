# Add Cri to load path
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../../vendor/cri/lib'))

# Load Cri
require 'cri'

# Module for CLI
module Nanoc3::CLI # :nodoc:
end

# Load CLI
require 'nanoc3/cli/logger'
require 'nanoc3/cli/commands'
require 'nanoc3/cli/base'
