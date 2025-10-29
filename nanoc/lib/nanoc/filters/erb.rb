# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class ERB < Nanoc::Filter
    identifier :erb

    requires 'erb'

    class << self
      attr_accessor :_erb_cache
    end

    self._erb_cache = {}

    # Runs the content through [ERB](http://ruby-doc.org/stdlib/libdoc/erb/rdoc/classes/ERB.html).
    #
    # @param [String] content The content to filter
    #
    # @option params [String] :trim_mode (nil) The trim mode to use
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Add locals
      assigns.merge!(params[:locals] || {})

      # Create context
      context = ::Nanoc::Core::Context.new(assigns)

      # Get binding
      proc = assigns[:content] ? -> { assigns[:content] } : nil
      assigns_binding = context.get_binding(&proc)

      # Get result
      trim_mode = params[:trim_mode]
      erb_for(content, trim_mode:).result(assigns_binding)
    end

    private

    def erb_for(content, trim_mode:)
      cache_key = [content, trim_mode]
      self.class._erb_cache.fetch(cache_key) do
        erb = ::ERB.new(content, trim_mode:)
        erb.filename = filename
        self.class._erb_cache[cache_key] = erb
        erb
      end
    end
  end
end
