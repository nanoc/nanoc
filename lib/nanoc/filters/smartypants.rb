module Nanoc::Filters
  class SmartyPants < Nanoc::Filter

    identifiers :smartypants, :rubypants

    def run(content)
      # Load requirements
      nanoc_require 'rubypants'

      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
