# frozen_string_literal: true

module Nanoc
  class IdentifiableCollectionView < ::Nanoc::View
    include Enumerable

    # @api private
    def initialize(objects, context)
      super(context)
      @objects = objects
    end

    # @api private
    def unwrap
      @objects
    end

    # @abstract
    #
    # @api private
    def view_class
      raise NotImplementedError
    end

    # Calls the given block once for each object, passing that object as a parameter.
    #
    # @yieldparam [#identifier] object
    #
    # @yieldreturn [void]
    #
    # @return [self]
    def each
      @context.dependency_tracker.bounce(unwrap, raw_content: true)
      @objects.each { |i| yield view_class.new(i, @context) }
      self
    end

    # @return [Integer]
    def size
      @context.dependency_tracker.bounce(unwrap, raw_content: true)
      @objects.size
    end

    # Finds all objects whose identifier matches the given argument.
    #
    # @param [String, Regex] arg
    #
    # @return [Enumerable]
    def find_all(arg)
      prop_attribute =
        case arg
        when String, Nanoc::Identifier
          [arg.to_s]
        when Regexp
          [arg]
        else
          true
        end

      @context.dependency_tracker.bounce(unwrap, raw_content: prop_attribute)
      @objects.find_all(arg).map { |i| view_class.new(i, @context) }
    end

    # @overload [](string)
    #
    #   Finds the object whose identifier matches the given string.
    #
    #   If the glob syntax is enabled, the string can be a glob, in which case
    #   this method finds the first object that matches the given glob.
    #
    #   @param [String] string
    #
    #   @return [nil] if no object matches the string
    #
    #   @return [#identifier] if an object was found
    #
    # @overload [](regex)
    #
    #   Finds the object whose identifier matches the given regular expression.
    #
    #   @param [Regex] regex
    #
    #   @return [nil] if no object matches the regex
    #
    #   @return [#identifier] if an object was found
    def [](arg)
      prop_attribute =
        case arg
        when String, Nanoc::Identifier
          [arg.to_s]
        when Regexp
          [arg]
        else
          true
        end

      @context.dependency_tracker.bounce(unwrap, raw_content: prop_attribute)
      res = @objects[arg]
      res && view_class.new(res, @context)
    end
  end
end
