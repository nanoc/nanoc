# encoding: utf-8

module Nanoc3::Filters
  class ERB < Nanoc3::Filter

    def run(content, params={})
      require 'erb'

      # Create context
      context = ::Nanoc3::Extra::Context.new(assigns)

      # Get result
      erb = ::ERB.new(content)
      erb.filename = filename
      erb.result(context.get_binding { assigns[:content] })
    end

  end
end
