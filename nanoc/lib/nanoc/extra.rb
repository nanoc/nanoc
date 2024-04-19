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
  Pruner = Nanoc::Core::Pruner
end

require_relative 'extra/srcset_parser'
require_relative 'extra/core_ext'
