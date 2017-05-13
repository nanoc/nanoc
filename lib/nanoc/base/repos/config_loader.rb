# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class ConfigLoader
    class NoConfigFileFoundError < ::Nanoc::Error
      def initialize
        super('No configuration file found')
      end
    end

    class NoParentConfigFileFoundError < ::Nanoc::Error
      def initialize(filename)
        super("There is no parent configuration file at #{filename}")
      end
    end

    class CyclicalConfigFileError < ::Nanoc::Error
      def initialize(filename)
        super("The parent configuration file at #{filename} includes one of its descendants")
      end
    end

    # @return [Boolean]
    def self.cwd_is_nanoc_site?
      !config_filename_for_cwd.nil?
    end

    # @return [String]
    def self.config_filename_for_cwd
      filenames = %w[nanoc.yaml config.yaml]
      candidate = filenames.find { |f| File.file?(f) }
      candidate && File.expand_path(candidate)
    end

    def new_from_cwd
      # Determine path
      filename = self.class.config_filename_for_cwd
      raise NoConfigFileFoundError if filename.nil?

      # Read
      config =
        apply_parent_config(
          Nanoc::Int::Configuration.new(hash: YAML.load_file(filename)),
          [filename],
        ).with_defaults

      # Load environment
      config.with_environment
    end

    # @api private
    def apply_parent_config(config, processed_paths = [])
      parent_path = config[:parent_config_file]
      return config if parent_path.nil?

      # Get absolute path
      parent_path = File.absolute_path(parent_path, File.dirname(processed_paths.last))
      unless File.file?(parent_path)
        raise NoParentConfigFileFoundError.new(parent_path)
      end

      # Check recursion
      if processed_paths.include?(parent_path)
        raise CyclicalConfigFileError.new(parent_path)
      end

      # Load
      parent_config = Nanoc::Int::Configuration.new(hash: YAML.load_file(parent_path))
      full_parent_config = apply_parent_config(parent_config, processed_paths + [parent_path])
      full_parent_config.merge(config.without(:parent_config_file))
    end
  end
end
