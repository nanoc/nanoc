# encoding: utf-8

# Load nanoc
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'nanoc3'

# Load tasks
Dir.glob('tasks/**/*.rake').each { |r| Rake.application.add_import r }

# Set default task
task :default => :test
