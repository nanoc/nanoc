module Nanoc::CLI

  class CompileCommand < Command

    def name
      'compile'
    end

    def aliases
      []
    end

    def short_desc
      'compile all pages of this site'
    end

    def long_desc
      'blah.'
    end

    def usage
      "nanoc compile [path]"
    end

    def run(options, arguments)
      puts "Compiling! :D"
    end

  end

end
