module Nanoc
  # @api private
  module Feature
    TRUES = %w(y yes 1 t true).freeze

    def self.enabled?(name)
      env_name = "NANOC_FEATURE_#{name.upcase}"
      TRUES.include?(ENV.fetch(env_name, 'f').downcase)
    end
  end
end
