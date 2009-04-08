module Nanoc3::Filters
  class Rainpress < Nanoc3::Filter

    def run(content)
      require 'rainpress'

      ::Rainpress.compress(content)
    end

  end
end
