# encoding: utf-8

module Nanoc3

  # The current nanoc version.
  VERSION = '3.1.0a1'

  # Loads all nanoc3 plugins, i.e. requires all ruby gems whose name start
  # with `nanoc3-`.
  #
  # @return [Boolean] true if all plugins were loaded successfully, false if
  #   rubygems isn’t loaded.
  def self.load_plugins
    # Don’t load if there’s no rubygems
    return false if !defined?(Gem)

    Gem.source_index.find_name('').each do |gem|
      # Skip irrelevant ones
      next if gem.name !~ /^nanoc3-/

      # Load plugin
      require gem.name
    end

    true
  end

end

# Load requirements
require 'yaml'
require 'fileutils'

# Load nanoc
require 'nanoc3/base'
require 'nanoc3/extra'
require 'nanoc3/data_sources'
require 'nanoc3/filters'
require 'nanoc3/helpers'

# Load plugins
Nanoc3.load_plugins
