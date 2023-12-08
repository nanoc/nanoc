# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    module YamlLoader
      OPTIONS = {
        permitted_classes: [Symbol, Date, Time].freeze,
        aliases: true,
      }.freeze

      private_constant :OPTIONS

      def self.load(yaml_string)
        YAML.safe_load(yaml_string, **OPTIONS)
      end

      def self.load_file(filename)
        YAML.safe_load_file(filename, **OPTIONS)
      end
    end
  end
end
