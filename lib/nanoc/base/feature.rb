module Nanoc
  # @api private
  module Feature
    PROFILER = 'profiler'.freeze
    ENVIRONMENTS = 'environments'.freeze

    def self.enabled_features
      @enabled_features ||= Set.new(ENV.fetch('NANOC_FEATURES', '').split(','))
    end

    def self.enabled?(feature_name)
      enabled_features.include?(feature_name) ||
        enabled_features.include?('all')
    end

    def self.reset_caches
      @enabled_features = nil
    end
  end
end
