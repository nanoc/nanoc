# frozen_string_literal: true

# Ruby stdlib
require 'singleton'
require 'tmpdir'

# External gems
require 'json_schema'
require 'ddmemoize'
require 'ddmetrics'
require 'ddplugin'
require 'hamster'
require 'slow_enumerator_tools'
require 'zeitwerk'

module Nanoc
  module Core
  end
end

DDMemoize.enable_metrics

inflector_class = Class.new(Zeitwerk::Inflector) do
  def camelize(basename, abspath)
    case basename
    when 'version'
      'VERSION'
    else
      super(basename.tr('-', '_'), abspath.tr('-', '_'))
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = inflector_class.new
loader.push_dir(__dir__ + '/..')
loader.ignore(__dir__ + '/../nanoc-core.rb')
loader.ignore(__dir__ + '/core/core_ext')
loader.setup
loader.eager_load

require_relative 'core/core_ext/array'
require_relative 'core/core_ext/hash'
require_relative 'core/core_ext/string'
