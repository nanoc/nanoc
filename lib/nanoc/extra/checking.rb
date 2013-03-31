# encoding: utf-8

module Nanoc::Extra

  module Checking

    require 'nanoc/extra/checking/check'
    require 'nanoc/extra/checking/dsl'
    require 'nanoc/extra/checking/runner.rb'
    require 'nanoc/extra/checking/issue'

  end

end

require 'nanoc/extra/checking/checks'
