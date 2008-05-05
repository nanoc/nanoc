module Nanoc::Filters
  class Markaby < Nanoc::Filter

    identifiers :markaby
    extensions  '.mab'

    def run(content)
      # Load requirements
      nanoc_require 'markaby'

      # Get result
      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end

  end
end
