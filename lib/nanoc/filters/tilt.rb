# encoding: utf-8

require 'tilt'

module Nanoc::Filters
  # Here is a sample compile rule (in the Rules file) which uses the tilt filter:
  #
  #     compile '*' do
  #       unless item.binary?
  #         filter :tilt if Tilt.registered?(item[:extension])
  #         layout 'common' if item[:extension] == 'erb'
  #       end
  #     end
  #
  # @since 3.2.0
  class Tilt < Nanoc::Filter
    
    # Runs the content through [tilt](https://github.com/rtomayko/tilt).
    #
    # @param [String] content The content to filter
    #
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'tilt'

      # Create context
      context = ::Nanoc::Context.new(assigns)

      # Get result
      proc = content ? lambda { content } : nil
      ::Tilt.new(path_to_tiltable_file_for(content, @item[:extension])).render(context, assigns, &proc)
    end

    protected
    def path_to_tiltable_file_for(content, extension)
      tempfile = Tempfile.new(["tilt", "." + extension])
      tempfile << content
      tempfile.close
      tempfile.path
    end
  end
end
