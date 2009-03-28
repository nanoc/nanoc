$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../../vendor/cri/lib'))
require 'cri'

module Nanoc::CLI # :nodoc:
end

require 'nanoc/cli/base'
require 'nanoc/cli/commands'
require 'nanoc/cli/logger'
