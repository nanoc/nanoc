module Nanoc::Filters
  class SmartyPants < Nanoc::Filter

    identifiers :smartypants, :rubypants

    def run(content)
      nanoc_require 'rubypants'

      ::RubyPants.new(content).to_html
    end

  end
end
