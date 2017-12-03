# frozen_string_literal: true

require 'nanoc/checking'
require 'nanoc/deploying'

# @api private
module Nanoc::Extra
  # @deprecated
  Checking = Nanoc::Checking

  # @deprecated
  Deployer = Nanoc::Deploying::Deployer

  # @deprecated
  Pruner = Nanoc::Pruner
end

require_relative 'extra/link_collector.rb'
require_relative 'extra/piper'
require_relative 'extra/jruby_nokogiri_warner'
require_relative 'extra/core_ext'
require_relative 'extra/parallel_collection'
