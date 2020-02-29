# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'codecov'
if ENV['CI'] == 'true'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

ENV['NANOC_DEV_MODE'] = 'true'

require 'fuubar'
require 'rspec/its'
require 'timecop'
require 'tty-command'
require 'yard'
