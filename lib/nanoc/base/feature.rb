# frozen_string_literal: true

module Nanoc
  # @api private
  #
  # @example Defining a feature and checking its enabledness
  #
  #     Nanoc::Feature.define('environments', version: '4.3')
  #     Nanoc::Feaure.enabled?(Nanoc::Feature::ENVIRONMENTS)
  #
  module Feature
    # Defines a new feature with the given name, experimental in the given
    # version. The feature will be made available as a constant with the same
    # name, in uppercase, on the Nanoc::Feature module.
    #
    # @example Defining Nanoc::Feature::ENVIRONMENTS
    #
    #     Nanoc::Feature.define('environments', version: '4.3')
    #
    # @param name The name of the feature
    #
    # @param version The minor version in which the feature is considered
    #   experimental.
    #
    # @return [void]
    def self.define(name, version:)
      repo[name] = version
      const_set(name.upcase, name)
    end

    # Undefines the feature with the given name. For testing purposes only.
    #
    # @param name The name of the feature
    #
    # @return [void]
    #
    # @private
    def self.undefine(name)
      repo.delete(name)
      remove_const(name.upcase)
    end

    # @param [String] feature_name
    #
    # @return [Boolean] Whether or not the feature with the given name is enabled
    def self.enabled?(feature_name)
      enabled_features.include?(feature_name) ||
        enabled_features.include?('all')
    end

    # @api private
    def self.enable(feature_name)
      raise ArgumentError, 'no block given' unless block_given?

      if enabled?(feature_name)
        yield
      else
        begin
          enabled_features << feature_name
          yield
        ensure
          enabled_features.delete(feature_name)
        end
      end
    end

    # @api private
    def self.reset_caches
      @enabled_features = nil
    end

    # @api private
    def self.enabled_features
      @enabled_features ||= Set.new(ENV.fetch('NANOC_FEATURES', '').split(','))
    end

    # @api private
    def self.repo
      @repo ||= {}
    end

    # @return [Enumerable<String>] Names of features that still exist, but
    #   should not be considered as experimental in the current version of
    #   Nanoc.
    def self.all_outdated
      repo.keys.reject do |name|
        version = repo[name]
        Nanoc::VERSION.start_with?(version)
      end
    end
  end
end
