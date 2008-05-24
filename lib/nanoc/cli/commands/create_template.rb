module Nanoc::CLI

  class CreateTemplateCommand < Command

    def name
      'create_template'
    end

    def aliases
      [ 'ct' ]
    end

    def short_desc
      'create a template'
    end

    def long_desc
      'blah.'
    end

    def run(options, arguments)
      puts "Creating a template! :D"
    end

  end

end
