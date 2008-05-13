module Nanoc

  # Code represent the custom code of a nanoc site. It contains the textual
  # source code as well as a mtime, to speed up site compilation.
  class Code

    attr_accessor :site
    attr_reader   :data, :mtime

    # Creates a new set of page defaults. +attributes+ is the metadata that
    # individual pages will override. +mtime+ is the time when the page
    # defaults were last modified (optional).
    def initialize(data, mtime=nil)
      @data  = data
      @mtime = mtime
    end

    # Loads the code by executing it.
    def load
      eval(@data, TOPLEVEL_BINDING)
    end

  end

end
