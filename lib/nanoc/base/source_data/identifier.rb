module Nanoc
  class Identifier
    include Comparable

    def self.from(obj)
      case obj
      when Nanoc::Identifier
        obj
      when String
        Nanoc::Identifier.new(obj)
      else
        raise ArgumentError, "Do not know how to convert #{obj} into a Nanoc::Identifier"
      end
    end

    def initialize(string, params = {})
      @type = params.fetch(:type, :full)

      case @type
      when :legacy
        @string = "/#{string}/".gsub(/^\/+|\/+$/, '/').freeze
      when :full
        if string !~ /\A\//
          raise Nanoc::Int::Errors::Generic,
            "Invalid identifier (does not start with a slash): #{string.inspect}"
        end
        @string = string.dup.freeze
      else
        raise Nanoc::Int::Errors::Generic,
          "Invalid :type param for identifier: #{@type.inspect}"
      end
    end

    def ==(other)
      to_s == other.to_s
    end
    alias_method :eql?, :==

    def hash
      self.class.hash ^ to_s.hash
    end

    def =~(pat)
      Nanoc::Int::Pattern.from(pat).match?(to_s) ? 0 : nil
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    # @return [Boolean] True if this is a full-type identifier (i.e. includes
    #   the extension), false otherwise
    def full?
      @type == :full
    end

    # @return [String]
    def chop
      to_s.chop
    end

    # @return [String]
    def +(string)
      to_s + string
    end

    # @return [Nanoc::Identifier]
    def prefix(string)
      if string !~ /\A\//
        raise Nanoc::Int::Errors::Generic,
          "Invalid prefix (does not start with a slash): #{@string.inspect}"
      end
      Nanoc::Identifier.new(string.sub(/\/+\z/, '') + @string, type: @type)
    end

    # @return [String]
    def with_ext(ext)
      unless full?
        raise Nanoc::Int::Errors::Generic,
          'Cannot use #with_ext on identifier that does not include the file extension'
      end

      # Strip extension, if any
      extname = File.extname(@string)
      string =
        if extname.size > 0
          @string[0..-extname.size - 1]
        else
          @string
        end

      # Add extension
      if ext.size > 0
        if ext.start_with?('.')
          string + ext
        else
          string + '.' + ext
        end
      else
        string
      end
    end

    # @return [String]
    def without_ext
      with_ext('')
    end

    def to_s
      @string
    end

    def to_str
      @string
    end

    def inspect
      "<Nanoc::Identifier type=#{@type} #{to_s.inspect}>"
    end
  end
end
