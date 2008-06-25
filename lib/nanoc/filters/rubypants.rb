module Nanoc::Filters
  class SmartyPants < Nanoc::Filter

    identifiers :rubypants

    def run(content)
      require 'rubypants'

      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
