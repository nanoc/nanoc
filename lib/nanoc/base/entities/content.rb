# encoding: utf-8

module Nanoc

  class Content

    attr_reader :filename

    def initialize(filename)
      self.validate_filename(filename)

      @filename = filename
    end

    def binary?
      raise NotImplementedError
    end

    def checksum
      raise NotImplementedError
    end

  protected

    def validate_filename(filename)
      if filename && !filename.start_with?('/')
        raise ArgumentError, "Filename should be absolute (got #{filename})"
      end
    end

  end

  class TextualContent < Content

    attr_reader :string

    def initialize(string, filename)
      super(filename)
      @string = string
    end

    def binary?
      false
    end

    def checksum
      digest = Digest::SHA1.new
      digest.update(@string)
      digest.hexdigest
    end

    def inspect
      "<#{self.class} filename=\"#{self.filename}\" string=\"#{self.string}\">"
    end

    def marshal_dump
      [ @string ]
    end

    def marshal_load(source)
      @string, _ = *source
    end

  end

  class BinaryContent < Content

    def binary?
      true
    end

    def checksum
      stat = File.stat(@filename)
      stat.size.to_s + '-' + stat.mtime.to_s
    end

    def inspect
      "<#{self.class} filename=\"#{self.filename}\">"
    end

    def marshal_dump
      [ @string, @filename ]
    end

    def marshal_load(source)
      @string, @filename = *source
    end

  end

end
