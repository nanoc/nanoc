# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class IdentifiableCollection
    include Nanoc::Int::ContractsSupport
    include Enumerable

    extend Nanoc::Int::Memoization
    extend Forwardable

    def_delegator :@objects, :each
    def_delegator :@objects, :size

    def initialize(*)
      raise 'IdentifiableCollection is abstract and cannot be instantiated'
    end

    contract C::Or[Hash, C::Named['Nanoc::Int::Configuration']], C::IterOf[C::RespondTo[:identifier]], C::Maybe[String] => C::Any
    def initialize_basic(config, objects = [], name = nil)
      @config = config
      @objects = Hamster::Vector.new(objects)
      @name = name
    end

    contract C::None => self
    def freeze
      @objects.freeze
      @objects.each(&:freeze)
      build_mapping
      super
    end

    contract C::Any => C::Maybe[C::RespondTo[:identifier]]
    def [](arg)
      if frozen?
        get_memoized(arg)
      else
        get_unmemoized(arg)
      end
    end

    contract C::Any => C::IterOf[C::RespondTo[:identifier]]
    def find_all(arg)
      if frozen?
        find_all_memoized(arg)
      else
        find_all_unmemoized(arg)
      end
    end

    contract C::None => C::ArrayOf[C::RespondTo[:identifier]]
    def to_a
      @objects.to_a
    end

    contract C::None => C::Bool
    def empty?
      @objects.empty?
    end

    def add(obj)
      self.class.new(@config, @objects.add(obj))
    end

    def reject(&block)
      self.class.new(@config, @objects.reject(&block))
    end

    def object_with_identifier(identifier)
      if frozen?
        @mapping[identifier.to_s]
      else
        @objects.find { |i| i.identifier == identifier }
      end
    end

    protected

    contract C::Any => C::Maybe[C::RespondTo[:identifier]]
    def get_unmemoized(arg)
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

    contract C::Any => C::Maybe[C::RespondTo[:identifier]]
    memoized def get_memoized(arg)
      get_unmemoized(arg)
    end

    contract C::Any => C::IterOf[C::RespondTo[:identifier]]
    def find_all_unmemoized(arg)
      pat = Nanoc::Int::Pattern.from(arg)
      select { |i| pat.match?(i.identifier) }
    end

    contract C::Any => C::IterOf[C::RespondTo[:identifier]]
    memoized def find_all_memoized(arg)
      find_all_unmemoized(arg)
    end

    def object_matching_glob(glob)
      if use_globs?
        pat = Nanoc::Int::Pattern.from(glob)
        @objects.find { |i| pat.match?(i.identifier) }
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
