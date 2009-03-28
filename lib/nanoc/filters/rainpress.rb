module Nanoc::Filters
  class Rainpress < Nanoc::Filter

    identifier :rainpress

    def run(content)
      require 'rainpress'

      ::Rainpress.compress(content)
    end

  end
end
