module Nanoc
  # @api private
  module Checking
    autoload 'Check',  'nanoc/checking/check'
    autoload 'DSL',    'nanoc/checking/dsl'
    autoload 'Runner', 'nanoc/checking/runner.rb'
    autoload 'Issue',  'nanoc/checking/issue'
  end
end

require 'nanoc/checking/checks'
