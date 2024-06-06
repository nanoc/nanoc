# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class DependencyProps
      include Nanoc::Core::ContractsSupport

      attr_reader :attributes
      attr_reader :raw_content

      # TODO: Split raw_content for documents and collections
      C_RAW_CONTENT =
        C::Or[
          C::SetOf[C::Or[String, Regexp]],
          C::ArrayOf[C::Or[String, Regexp]],
          C::Bool
        ]

      C_ATTR =
        C::Or[
          C::SetOf[
            C::Or[
              Symbol,          # any value
              [Symbol, C::Any] # pair (specific value)
            ],
          ],
          C::ArrayOf[
            C::Or[
              Symbol,          # any value
              [Symbol, C::Any] # pair (specific value)
            ],
          ],
          C::Bool
        ]

      C_ARGS =
        C::KeywordArgs[
          raw_content: C::Optional[C_RAW_CONTENT],
          attributes: C::Optional[C_ATTR],
          compiled_content: C::Optional[C::Bool],
          path: C::Optional[C::Bool]
        ]

      contract C_ARGS => C::Any
      def initialize(raw_content: false, attributes: false, compiled_content: false, path: false)
        @compiled_content = compiled_content
        @path = path

        @attributes =
          case attributes
          when Set
            attributes
          when Array
            Set.new(attributes)
          else
            attributes
          end

        @raw_content =
          case raw_content
          when Set
            raw_content
          when Array
            Set.new(raw_content)
          else
            raw_content
          end
      end

      contract C::None => String
      def inspect
        (+'').tap do |s|
          s << 'Props('
          s << (raw_content? ? 'r' : '_')
          s << (attributes? ? 'a' : '_')
          s << (compiled_content? ? 'c' : '_')
          s << (path? ? 'p' : '_')

          if @raw_content.is_a?(Set)
            @raw_content.each do |elem|
              s << '; raw_content('
              s << elem.inspect
              s << ')'
            end
          end

          if @attributes.is_a?(Set)
            @attributes.each do |elem|
              s << '; attr('
              s << elem.inspect
              s << ')'
            end
          end

          s << ')'
        end
      end

      contract C::None => String
      def to_s
        (+'').tap do |s|
          s << (raw_content? ? 'r' : '_')
          s << (attributes? ? 'a' : '_')
          s << (compiled_content? ? 'c' : '_')
          s << (path? ? 'p' : '_')
        end
      end

      contract C::None => C::Bool
      def raw_content?
        case @raw_content
        when Set
          !@raw_content.empty?
        else
          @raw_content
        end
      end

      contract C::None => C::Bool
      def attributes?
        case @attributes
        when Set
          !@attributes.empty?
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

      contract Nanoc::Core::DependencyProps => Nanoc::Core::DependencyProps
      def merge(other)
        DependencyProps.new(
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

      def attribute_keys
        case @attributes
        when Enumerable
          @attributes.map { |a| a.is_a?(Array) ? a.first : a }
        else
          []
        end
      end

      contract C::None => Hash
      def to_h
        {
          raw_content:,
          attributes:,
          compiled_content: compiled_content?,
          path: path?,
        }
      end
    end
  end
end
