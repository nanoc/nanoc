module Nanoc::Int
  # @api private
  class Props
    def initialize(raw_content: false, attributes: false, compiled_content: false, path: false)
      @raw_content = raw_content
      @attributes = attributes
      @compiled_content = compiled_content
      @path = path
    end

    def raw_content?
      @raw_content
    end

    def attributes?
      @attributes
    end

    def compiled_content?
      @compiled_content
    end

    def path?
      @path
    end

    def merge(other)
      Props.new(
        raw_content: raw_content? || other.raw_content?,
        attributes: attributes? || other.attributes?,
        compiled_content: compiled_content? || other.compiled_content?,
        path: path? || other.path?,
      )
    end

    def active
      Set.new.tap do |pr|
        pr << :raw_content if raw_content?
        pr << :attributes if attributes?
        pr << :compiled_content if compiled_content?
        pr << :path if path?
      end
    end
  end
end
