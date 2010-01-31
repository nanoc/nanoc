# encoding: utf-8

module Nanoc3::Filters
  class Erubis < Nanoc3::Filter

    def run(content, params={})
      require 'erubis'

      # Create context
      context = ::Nanoc3::Context.new(assigns)

      # Get result
      ::Erubis::Eruby.new(content, :filename => filename).result(context.get_binding { assigns[:content] })
    end

  end
end
