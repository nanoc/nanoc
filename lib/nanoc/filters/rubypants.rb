module Nanoc::Filters
  class SmartyPants < Nanoc::Filter

    identifier :rubypants

    def run(content)
      require 'rubypants'

      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
