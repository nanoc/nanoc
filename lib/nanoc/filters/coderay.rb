# encoding: utf-8

require 'coderay'

module Nanoc::Filters
  class CodeRay < Nanoc::Filter

    # @deprecated Use the `:colorize_syntax` filter instead.
    def run(content, params={})
      # Warn
      warn 'The :coderay filter is deprecated; consider using the :colorize_syntax filter instead.'

      # Check params
      raise ArgumentError, "CodeRay filter requires a :language argument which is missing" if params[:language].nil?

      # Get result
      ::CodeRay.scan(content, params[:language]).html
    end

  end
end
