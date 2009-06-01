# encoding: utf-8

module Nanoc3::Filters
  class Markaby < Nanoc3::Filter

    def run(content, params={})
      require 'markaby'

      # Get result
      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end

  end
end
