# encoding: utf-8

module Nanoc

  # Creates checksums for given objects.
  #
  # A checksum is a string, such as “mL+TaqNsEeiPkWloPgCtAofT1yg=”, that is used
  # to determine whether a piece of data has changed.
  class Checksummer

    class << self

      # @param obj The object to create a checksum for
      #
      # @return [String] The digest
      def calc(obj)
        digest = Digest::SHA1.new
        update(obj, digest)
        digest.base64digest
      end

    private

      def update(obj, digest)
        digest.update(obj.class.to_s)

        case obj
        when String
          digest.update(obj)
        when Array
          obj.each do |el|
            digest.update('elem')
            update(el, digest)
          end
        when Hash
          obj.each do |key, value|
            digest.update('key')
            update(key, digest)
            digest.update('value')
            update(value, digest)
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
          update(obj.data, digest)
        when Nanoc::CodeSnippet
          update(obj.data, digest)
        when Nanoc::Item, Nanoc::Layout
          digest.update('content')
          if obj.respond_to?(:binary?) && obj.binary?
            update(Pathname.new(obj.raw_filename), digest)
          else
            update(obj.raw_content, digest)
          end

          digest.update('attributes')
          attributes = obj.attributes.dup
          attributes.delete(:file)
          update(attributes, digest)
        else
          data = begin
            Marshal.dump(obj)
          rescue
            obj.inspect
          end

          digest.update(data)
        end

      end

    end

  end

end
