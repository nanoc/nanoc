module Nanoc
  # @api private
  module Feature
    FEATURES_VAR_NAME = 'NANOC_FEATURES'.freeze
    ALL_VALUE = 'all'.freeze

    def self.enabled_features
      Set.new(ENV.fetch(FEATURES_VAR_NAME, '').split(','))
    end

    def self.enabled?(feature_name)
      enabled_features.include?(feature_name) ||
        enabled_features.include?(ALL_VALUE)
    end
  end
end
