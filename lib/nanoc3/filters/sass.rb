module Nanoc3::Filters
  class Sass < Nanoc3::Filter

    def run(content, params={})
      require 'sass'

      # Get options
      symbolized_params = params.inject({}) { |m,(k,v)| m.merge(k => v.to_sym) }
      options = symbolized_params
      options[:filename] = filename

      # Get result
      ::Sass::Engine.new(content, options).render
    end

  end
end
