# frozen_string_literal: true

module Nanoc
  module Core
    class IdentifiableCollectionView < ::Nanoc::Core::View
      include Enumerable

      NOTHING = Object.new

      # @api private
      def initialize(objects, context)
        super(context)
        @objects = objects
      end

      # @api private
      def _unwrap
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
        @context.dependency_tracker.bounce(_unwrap, raw_content: true)
        @objects.each { |i| yield view_class.new(i, @context) }
        self
      end

      # @return [Integer]
      def size
        @context.dependency_tracker.bounce(_unwrap, raw_content: true)
        @objects.size
      end

      # Finds all objects whose identifier matches the given argument.
      #
      # @param [String, Regex] arg
      #
      # @return [Enumerable]
      def find_all(arg = NOTHING, &)
        if NOTHING.equal?(arg)
          @context.dependency_tracker.bounce(_unwrap, raw_content: true)
          return @objects.map { |i| view_class.new(i, @context) }.select(&)
        end

        prop_attribute =
          case arg
          when String, Nanoc::Core::Identifier
            [arg.to_s]
          when Regexp
            [arg]
          else
            true
          end

        @context.dependency_tracker.bounce(_unwrap, raw_content: prop_attribute)
        @objects.find_all(arg).map { |i| view_class.new(i, @context) }
      end

      # Finds all objects that have the given attribute key/value pair.
      #
      # @example
      #
      #     @items.where(kind: 'article')
      #     @items.where(kind: 'article', year: 2020)
      #
      # @return [Enumerable]
      def where(**hash)
        unless Nanoc::Core::Feature.enabled?(Nanoc::Core::Feature::WHERE)
          raise(
            Nanoc::Core::TrivialError,
            '#where is experimental, and not yet available unless the corresponding feature flag is turned on. Set the `NANOC_FEATURES` environment variable to `where` to enable its usage. (Alternatively, set the environment variable to `all` to turn on all feature flags.)',
          )
        end

        @context.dependency_tracker.bounce(_unwrap, attributes: hash)

        # IDEA: Nanoc could remember (from the previous compilation) how many
        # times #where is called with a given attribute key, and memoize the
        # key-to-identifiers list.
        found_objects = @objects.select do |i|
          hash.all? { |k, v| i.attributes[k] == v }
        end

        found_objects.map { |i| view_class.new(i, @context) }
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
        # The argument to #[] fall in two categories: exact matches, and
        # patterns. An example of an exact match is '/about.md', while an
        # example of a pattern is '/about.*'.
        #
        # If a Nanoc::Core::Identifier is given, we know it will need to be an
        # exact match. If a String is given, it could be either. If a Regexp is
        # given, we know it’s a pattern match.
        #
        # If we have a pattern match, create a dependency on the item
        # collection, with a `raw_content` property that contains the pattern.
        # If we have an exact match, do nothing -- there is no reason to create
        # a dependency on the item itself, because accessing that item
        # (attributes, compiled content, …) will create the dependency later.

        object_from_exact_match = nil
        object_from_pattern_match = nil

        case arg
        when Nanoc::Core::Identifier
          # Can only be an exact match
          object_from_exact_match = @objects.object_with_identifier(arg)
        when String
          # Can be an exact match, or a pattern match
          tmp = @objects.object_with_identifier(arg)
          if tmp
            object_from_exact_match = tmp
          else
            object_from_pattern_match = @objects.object_matching_glob(arg)
          end
        when Regexp
          # Can only be a pattern match
          object_from_pattern_match = @objects.find { |i| i.identifier.to_s =~ arg }
        else
          raise ArgumentError, "Unexpected argument #{arg.class} to []: Can only pass strings, identfiers, and regular expressions"
        end

        unless object_from_exact_match
          # We got this object from a pattern match. Create a dependency with
          # this pattern, because if the objects matching this pattern change,
          # then the result of #[] will change too.
          #
          # NOTE: object_from_exact_match can also be nil, but in that case
          # we still need to create a dependency.

          prop_attribute =
            case arg
            when Identifier
              [arg.to_s]
            when String, Regexp
              [arg]
            end

          @context.dependency_tracker.bounce(_unwrap, raw_content: prop_attribute)
        end

        object = object_from_exact_match || object_from_pattern_match
        object && view_class.new(object, @context)
      end
    end
  end
end
