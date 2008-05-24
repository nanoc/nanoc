module Nanoc::CLI

  class CreateLayoutCommand < Command

    def name
      'create_layout'
    end

    def aliases
      [ 'cl' ]
    end

    def short_desc
      'create a layout'
    end

    def long_desc
      'blah.'
    end

    def run(options, arguments)
      puts "Creating a layout! :D"
    end

  end

end
