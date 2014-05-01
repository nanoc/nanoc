# encoding: utf-8

module Nanoc

  # Creates checksums for given objects.
  #
  # A checksum is a string, such as “mL+TaqNsEeiPkWloPgCtAofT1yg=”, that is used
  # to determine whether a piece of data has changed.
  #
  # A checksummer is stateless.
  class Checksummer

    # @return [Nanoc::Checksummer] A global stateless checksummer
    def self.instance
      @_instance ||= self.new
    end

    # @param obj The object to create a checksum for
    #
    # @return [String] The digest
    def self.calc(obj)
      instance.calc(obj)
    end

    # @param obj The object to create a checksum for
    #
    # @param [Digest::Base] digest An existing digest to append to
    #
    # @return [String] The digest
    def calc(obj, digest = Digest::SHA1.new)
      digest.update(obj.class.to_s)

      case obj
      when String
        digest.update(obj)
      when Array
        obj.each do |el|
          digest.update('elem')
          calc(el, digest)
        end
      when Hash
        obj.each do |key, value|
          digest.update('key')
          calc(key, digest)
          digest.update('value')
          calc(value, digest)
        end
      when Pathname
        filename = obj.to_s
        if File.exist?(filename)
          stat = File.stat(filename)
          digest.update(stat.size.to_s + '-' + stat.mtime.utc.to_s)
        else
          digest.update('???')
        end
      when Nanoc::RulesCollection
        calc(obj.data, digest)
      when Nanoc::CodeSnippet
        calc(obj.data, digest)
      when Nanoc::Item, Nanoc::Layout
        digest.update('content')
        if obj.respond_to?(:binary?) && obj.binary?
          calc(Pathname.new(obj.raw_filename), digest)
        else
          calc(obj.raw_content, digest)
        end

        digest.update('attributes')
        attributes = obj.attributes.dup
        attributes.delete(:file)
        calc(attributes, digest)
      else
        data = begin
          Marshal.dump(obj)
        rescue
          obj.inspect
        end

        digest.update(data)
      end

      digest.base64digest
    end

  end

end
