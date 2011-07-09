# encoding: utf-8

# Set up env
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require './test/gem_loader.rb'

# Load nanoc
require 'nanoc'

# Load tasks
Dir.glob('tasks/**/*.rake').each { |r| Rake.application.add_import r }

# Set default task
task :default => :test
