# encoding: utf-8

module Nanoc3

  # Nanoc3::CodeSnippet represent a piece of custom code of a nanoc site.
  class CodeSnippet

    # The {Nanoc3::Site} this code snippet belongs to.
    #
    # @return [Nanoc3::Site]
    attr_accessor :site

    # A string containing the actual code in this code snippet.
    #
    # @return [String]
    attr_reader :data

    # The filename corresponding to this code snippet.
    #
    # @return [String]
    attr_reader :filename

    # @return [String] The checksum of this code snippet that was in effect
    #   during the previous site compilation
    attr_accessor :old_checksum

    # @return [String] The current, up-to-date checksum of this code snippet
    attr_reader   :new_checksum

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
    # @option params [String, nil] :checksum (nil) The current, up-to-date
    #   checksum of this code snippet
    def initialize(data, filename, params=nil)
      # Get mtime and checksum
      params ||= {}
      params = { :mtime => params } if params.is_a?(Time)
      @new_checksum = params[:checksum]
      @mtime        = params[:mtime]

      @data     = data
      @filename = filename
    end

    # Loads the code by executing it.
    #
    # @return [void]
    def load
      eval(@data, TOPLEVEL_BINDING, @filename)
    end

    # @return [Boolean] true if the code snippet was modified since it was
    #   last compiled, false otherwise
    def outdated?
      !self.old_checksum || !self.new_checksum || self.new_checksum != self.old_checksum
    end

  end

end
