module Nanoc3::Filters
  class RubyPants < Nanoc3::Filter

    def run(content)
      require 'rubypants'

      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
