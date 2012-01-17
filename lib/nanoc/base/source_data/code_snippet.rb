# encoding: utf-8

module Nanoc

  # Nanoc::CodeSnippet represent a piece of custom code of a nanoc site.
  class CodeSnippet

    # A string containing the actual code in this code snippet.
    #
    # @return [String]
    attr_reader :data

    # The filename corresponding to this code snippet.
    #
    # @return [String]
    attr_reader :filename

    # Creates a new code snippet.
    #
    # @param [String] data The raw source code which will be executed before
    #   compilation
    #
    # @param [String] filename The filename corresponding to this code snippet
    #
    # @param [Time, Hash] params Extra parameters. Ignored by nanoc; it is
    #   only included for backwards compatibility.
    def initialize(data, filename, params=nil)
      @data     = data
      @filename = filename
    end

    # Loads the code by executing it.
    #
    # @return [void]
    def load
      eval(@data, TOPLEVEL_BINDING, @filename)
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @return [Object] An unique reference to this object
    def reference
      [ :code_snippet, filename ]
    end

    def inspect
      "<#{self.class} filename=#{self.filename}>"
    end

    # @return [String] The checksum for this object. If its contents change,
    #   the checksum will change as well.
    def checksum
      @data.checksum
    end

  end

end
