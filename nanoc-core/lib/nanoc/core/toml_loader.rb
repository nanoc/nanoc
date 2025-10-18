# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    module TomlLoader
      def self.load(string)
        require 'perfect_toml'
        PerfectTOML.parse(string)
      end

      def self.load_file(filename)
        require 'perfect_toml'
        load(File.read(filename))
      end
    end
  end
end
