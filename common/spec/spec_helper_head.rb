# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'timecop'
require 'rspec/its'
require 'fuubar'
require 'yard'

require 'nanoc'
require 'nanoc/cli'
require 'nanoc/spec'
