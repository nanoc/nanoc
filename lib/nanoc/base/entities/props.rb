# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Props
    include Nanoc::Int::ContractsSupport

    attr_reader :attributes
    attr_reader :raw_content

    # TODO: Split raw_content for documents and collections
    C_RAW_CONTENT = C::Or[C::IterOf[C::Or[String, Regexp]], C::Bool]
    C_ATTRS = C::Or[C::IterOf[Symbol], C::Bool]
    contract C::KeywordArgs[raw_content: C::Optional[C_RAW_CONTENT], attributes: C::Optional[C_ATTRS], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
    def initialize(raw_content: false, attributes: false, compiled_content: false, path: false)
      @compiled_content = compiled_content
      @path = path

      @attributes =
        case attributes
        when Enumerable
          Set.new(attributes)
        else
          attributes
        end

      @raw_content =
        case raw_content
        when Enumerable
          Set.new(raw_content)
        else
          raw_content
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
      case @raw_content
      when Enumerable
        @raw_content.any?
      else
        @raw_content
      end
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
        raw_content: merge_raw_content(other),
        attributes: merge_attributes(other),
        compiled_content: compiled_content? || other.compiled_content?,
        path: path? || other.path?,
      )
    end

    def merge_raw_content(other)
      merge_prop(raw_content, other.raw_content)
    end

    def merge_attributes(other)
      merge_prop(attributes, other.attributes)
    end

    def merge_prop(own, other)
      case own
      when true
        true
      when false
        other
      else
        case other
        when true
          true
        when false
          own
        else
          own + other
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
        raw_content: raw_content,
        attributes: attributes,
        compiled_content: compiled_content?,
        path: path?,
      }
    end
  end
end
