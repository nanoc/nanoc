# encoding: utf-8

module Nanoc3

  # Nanoc3::CodeSnippet represent a piece of custom code of a nanoc site.
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
    # @param [Time, Hash] params Extra parameters. For backwards
    #   compatibility, this can be a Time instance indicating the time when
    #   this code snippet was last modified (mtime).
    #
    # @option params [Time, nil] :mtime (nil) The time when this code snippet
    #   was last modified
    #
    # FIXME maybe change the arguments back to what they were?
    def initialize(data, filename, params=nil)
      # Parse params
      params ||= {}
      params = { :mtime => params } if params.is_a?(Time)

      @data     = data
      @filename = filename
      @mtime    = params[:mtime]
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

  end

end
