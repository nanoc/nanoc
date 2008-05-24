module Nanoc::CLI

  class CreatePageCommand < Command

    def name
      'create_page'
    end

    def aliases
      [ 'cp' ]
    end

    def short_desc
      'create a page'
    end

    def long_desc
      'blah.'
    end

    def run(options, arguments)
      puts "Creating a page! :D"
    end

  end

end
