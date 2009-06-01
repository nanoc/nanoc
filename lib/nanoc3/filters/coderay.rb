# encoding: utf-8

module Nanoc3::Filters
  class CodeRay < Nanoc3::Filter

    def run(content, params={})
      require 'coderay'

      # Check params
      raise ArgumentError, "CodeRay filter requires a :language argument which is missing" if params[:language].nil?

      # Get result
      ::CodeRay.scan(content, params[:language]).html
    end

  end
end
