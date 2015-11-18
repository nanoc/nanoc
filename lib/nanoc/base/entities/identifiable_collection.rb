module Nanoc::Int
  # @api private
  class IdentifiableCollection
    include Enumerable

    extend Forwardable

    def_delegator :@objects, :each
    def_delegator :@objects, :size
    def_delegator :@objects, :<<
    def_delegator :@objects, :concat

    def initialize(config, data_sources = nil)
      @config = config
      @data_sources = data_sources

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
      if pattern.is_a?(Nanoc::Int::StringPattern)
        if use_globs?
          method =
            case @objects.first
            when Nanoc::Int::Layout
              :glob_layout
            when Nanoc::Int::Item
              :glob_item
            else
              raise "Unknown type: #{@objects.first.class}"
            end

          @data_sources.lazy.flat_map do |ds|
            if ds.respond_to?(method)
              paths = ds.send(method, pattern.to_s)
              paths.lazy.map { |path| object_with_identifier(path) }
            end
          end
        else
          # FIXME: support legacy pattern
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
      pattern = Nanoc::Int::Pattern.from(glob)
      objects_matching_pattern(pattern).first
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
