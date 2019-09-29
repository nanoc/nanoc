# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'codecov'
if ENV['CI'] == 'true'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'fuubar'
require 'rspec/its'
require 'timecop'
require 'tty-command'
require 'yard'
