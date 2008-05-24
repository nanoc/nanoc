module Nanoc::CLI

  class CompileCommand < Command

    def name
      'compile'
    end

    def aliases
      []
    end

    def short_desc
      'compile pages of this site'
    end

    def long_desc
      'Compile all pages of the current site. If a path is given, only ' +
      'the page with the given path will be compiled. Additionally, only ' +
      'pages that are outdated will be compiled, unless specified ' +
      'otherwise with the -a option.'
    end

    def usage
      "nanoc compile [options] [path]"
    end

    def option_definitions
      [
        # --all
        {
          :long => 'all', :short => 'a', :argument => :forbidden,
          :desc => 'Compile all pages, even those that aren\'t outdated.'
        }
      ]
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      if @base.site.nil?
        puts 'The current working directory does not seem to be a ' +
             'valid/complete nanoc site directory; aborting.'
        exit 1
      end

      # Compile site
      @base.site.compile(arguments[0], options.has_key?(:all))
    end

  end

end
