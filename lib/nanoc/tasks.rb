# encoding: utf-8

require 'nanoc'
require 'rake'

# @api private
module Nanoc::Tasks
end

Dir[File.dirname(__FILE__) + '/tasks/**/*.rb'].each   { |f| load f }
Dir[File.dirname(__FILE__) + '/tasks/**/*.rake'].each { |f| Rake.application.add_import(f) }
