module Nanoc::Int
  # @api private
  class IdentifiableCollection
    include Enumerable

    extend Forwardable

    def_delegator :@objects, :each
    def_delegator :@objects, :size
    def_delegator :@objects, :<<
    def_delegator :@objects, :concat

    def initialize(config, document_sources = nil)
      @config = config
      @document_sources = document_sources

      @objects = []
    end

    def freeze
      @objects.freeze
      build_mapping
      super
    end

    def [](arg)
      case arg
      when Nanoc::Identifier
        object_with_identifier(arg)
      when String
        object_with_identifier(arg) || object_matching_glob(arg)
      when Regexp
        @objects.find { |i| i.identifier.to_s =~ arg }
      else
        raise ArgumentError, "don’t know how to fetch objects by #{arg.inspect}"
      end
    end

    def to_a
      @objects
    end

    def empty?
      @objects.empty?
    end

    def delete_if(&block)
      @objects.delete_if(&block)
    end

    def objects_matching_pattern(pattern)
      # TODO: verify type of pattern
      if pattern.is_a?(Nanoc::Int::StringPattern) && @document_sources
        if use_globs?
          # FIXME: fails when adding documents with preprocessor
          # (maybe turn preprocessor into data source?)
          paths = @document_sources.flat_map { |ds| ds.paths_matching_pattern(pattern) }
          paths.map { |path| self[path] }
        else
          []
        end
      else
        @objects.lazy.select { |i| pattern.match?(i.identifier) }
      end
    end

    protected

    def object_with_identifier(identifier)
      if self.frozen?
        @mapping[identifier.to_s]
      else
        @objects.find { |i| i.identifier == identifier }
      end
    end

    def object_matching_glob(glob)
      if use_globs?
        pat = Nanoc::Int::Pattern.from(glob)
        objects_matching_pattern(pat).first
      else
        nil
      end
    end

    def build_mapping
      @mapping = {}
      @objects.each do |object|
        @mapping[object.identifier.to_s] = object
      end
      @mapping.freeze
    end

    def use_globs?
      @config[:string_pattern_type] == 'glob'
    end
  end
end
