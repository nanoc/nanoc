# frozen_string_literal: true

require 'nanoc/core'

module Nanoc
  # @api private
  module CLI
  end
end

inflector_class = Class.new(Zeitwerk::Inflector) do
  def camelize(basename, abspath)
    case basename
    when 'version', 'cli', 'utf8'
      basename.upcase
    when 'ansi_colors'
      'ANSIColors'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = inflector_class.new
loader.push_dir(__dir__ + '/..')
loader.ignore(__dir__ + '/../nanoc-cli.rb')
loader.ignore(__dir__ + '/cli/commands')
loader.setup
loader.eager_load
