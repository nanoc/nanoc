module Nanoc
  class IdentifiableCollectionView
    include Enumerable

    # @api private
    def initialize(objects)
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
      @objects.each { |i| yield view_class.new(i, nil) }
      self
    end

    # @return [Integer]
    def size
      @objects.size
    end

    # Finds all objects whose identifier matches the given argument.
    #
    # @param [String, Regex] arg
    #
    # @return [Enumerable]
    def find_all(arg)
      pat = Nanoc::Int::Pattern.from(arg)
      select { |i| pat.match?(i.identifier) }
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
      res = @objects[arg]
      res && view_class.new(res, nil)
    end
  end
end
