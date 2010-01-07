# encoding: utf-8

module Nanoc3::Filters
  class Rainpress < Nanoc3::Filter

    def run(content, params={})
      require 'rainpress'

      ::Rainpress.compress(content, params)
    end

  end
end
