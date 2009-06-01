# encoding: utf-8

module Nanoc3

  # Nanoc3::Code represent the custom code of a nanoc site. It contains the
  # textual source code as well as a mtime, which is used to speed up site
  # compilation.
  class Code

    # The Nanoc3::Site this code belongs to.
    attr_accessor :site

    # The snippets that make up the code, consisting of a an array of hashes
    # with +:filename+ and +:code+ keys.
    attr_reader :snippets

    # The time where the code was last modified.
    attr_reader :mtime

    # Creates a new code object. +data+ is the raw source code, which will be
    # executed before compilation. +mtime+ is the time when the code was last
    # modified (optional).
    def initialize(arg, mtime=nil)
      if arg.is_a? String
        @snippets = [ { :filename => nil, :code => arg } ]
      else
        @snippets = arg
      end

      @mtime = mtime
    end

    # Loads the code by executing it.
    def load
      @snippets.each do |snippet|
        eval(snippet[:code], TOPLEVEL_BINDING, snippet[:filename] || '?')
      end
    end

  end

end
