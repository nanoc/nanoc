# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Props
    include Nanoc::Int::ContractsSupport

    attr_reader :attributes

    C_ATTRS = C::Or[C::IterOf[Symbol], C::Bool]
    contract C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C_ATTRS], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
    def initialize(raw_content: false, attributes: false, compiled_content: false, path: false)
      @raw_content = raw_content
      @compiled_content = compiled_content
      @path = path

      @attributes =
        case attributes
        when Enumerable
          Set.new(attributes)
        else
          attributes
        end
    end

    contract C::None => String
    def inspect
      String.new.tap do |s|
        s << 'Props('
        s << (raw_content? ? 'r' : '_')
        s << (attributes? ? 'a' : '_')
        s << (compiled_content? ? 'c' : '_')
        s << (path? ? 'p' : '_')
        s << ')'
      end
    end

    contract C::None => C::Bool
    def raw_content?
      @raw_content
    end

    contract C::None => C::Bool
    def attributes?
      case @attributes
      when Enumerable
        @attributes.any?
      else
        @attributes
      end
    end

    contract C::None => C::Bool
    def compiled_content?
      @compiled_content
    end

    contract C::None => C::Bool
    def path?
      @path
    end

    contract Nanoc::Int::Props => Nanoc::Int::Props
    def merge(other)
      Props.new(
        raw_content: raw_content? || other.raw_content?,
        attributes: merge_attributes(other),
        compiled_content: compiled_content? || other.compiled_content?,
        path: path? || other.path?,
      )
    end

    def merge_attributes(other)
      case attributes
      when true
        true
      when false
        other.attributes
      else
        case other.attributes
        when true
          true
        when false
          attributes
        else
          attributes + other.attributes
        end
      end
    end

    contract C::None => Set
    def active
      Set.new.tap do |pr|
        pr << :raw_content if raw_content?
        pr << :attributes if attributes?
        pr << :compiled_content if compiled_content?
        pr << :path if path?
      end
    end

    contract C::None => Hash
    def to_h
      {
        raw_content: raw_content?,
        attributes: attributes,
        compiled_content: compiled_content?,
        path: path?,
      }
    end
  end
end
