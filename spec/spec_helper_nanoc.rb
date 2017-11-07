# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'nanoc'
require 'nanoc/cli'

require_relative 'spec_helper_common'
