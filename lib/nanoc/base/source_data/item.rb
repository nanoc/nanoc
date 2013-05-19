# encoding: utf-8

module Nanoc

  # Represents a compileable item in a site. It has content and attributes, as
  # well as an identifier (which starts and ends with a slash). It can also
  # store the modification time to speed up compilation.
  class Item < ContentPiece

    extend Nanoc::Memoization

    # @return [Array<Nanoc::ItemRep>] This item’s list of item reps
    attr_reader :reps

    # @see Nanoc::ContentPiece#initialize
    def initialize(content_or_filename, attributes, identifier, params={})
      super
      @reps = []
    end

    # Returns the rep with the given name.
    #
    # @param [Symbol] rep_name The name of the representation to return
    #
    # @return [Nanoc::ItemRep] The representation with the given name
    def rep_named(rep_name)
      @reps.find { |r| r.name == rep_name }
    end

    # Returns the compiled content from a given representation and a given
    # snapshot. This is a convenience method that makes fetching compiled
    # content easier.
    #
    # @option params [String] :rep (:default) The name of the representation
    #   from which the compiled content should be fetched. By default, the
    #   compiled content will be fetched from the default representation.
    #
    # @option params [String] :snapshot The name of the snapshot from which to
    #   fetch the compiled content. By default, the returned compiled content
    #   will be the content compiled right before the first layout call (if
    #   any).
    #
    # @return [String] The compiled content of the given rep (or the default
    #   rep if no rep is specified) at the given snapshot (or the default
    #   snapshot if no snapshot is specified)
    #
    # @see ItemRep#compiled_content
    def compiled_content(params={})
      # Get rep
      rep_name = params[:rep] || :default
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's content
      rep.compiled_content(params)
    end

    # Returns the path from a given representation. This is a convenience
    # method that makes fetching the path of a rep easier.
    #
    # @option params [String] :rep (:default) The name of the representation
    #   from which the path should be fetched. By default, the path will be
    #   fetched from the default representation.
    #
    # @return [String] The path of the given rep ( or the default rep if no
    #   rep is specified)
    def path(params={})
      rep_name = params[:rep] || :default

      # Get rep
      rep = reps.find { |r| r.name == rep_name }
      if rep.nil?
        raise Nanoc::Errors::Generic,
          "No rep named #{rep_name.inspect} was found."
      end

      # Get rep's path
      rep.path
    end

    # Returns the type of this object. Will always return `:item`, because
    # this is an item. For layouts, this method returns `:layout`.
    #
    # @api private
    #
    # @return [Symbol] :item
    def type
      :item
    end

    # @return [String] The checksum for this object. If its contents change,
    #   the checksum will change as well.
    def checksum
      content_checksum = if binary?
        if File.exist?(filename)
          Pathname.new(filename).checksum
        else
          ''.checksum
        end
      else
        @content.checksum
      end

      attributes = @attributes.dup
      attributes.delete(:file)
      attributes_checksum = attributes.checksum

      content_checksum + ',' + attributes_checksum
    end
    memoize :checksum

    def marshal_dump
      [
        @is_binary,
        @filename,
        @content,
        @attributes,
        @identifier
      ]
    end

    def marshal_load(source)
      @is_binary,
      @filename,
      @content,
      @attributes,
      @identifier = *source
    end

    # @api private
    def forced_outdated=(bool)
      @forced_outdated = bool
    end

    # @api private
    def forced_outdated?
      @forced_outdated || false
    end

  end

end
