require 'set'
require 'fileutils'

module Nanoc::Int
  module DDDB
    def self.new(filename)
      DB.new(filename)
    end

    class DataFile
      def initialize(filename)
        @filename = filename
      end

      def open
        @io = File.open(@filename, File::RDWR | File::CREAT | File::BINARY, 0o644)
        @size = File.size(@filename)
      end

      def reopen
        close if @io
        open
      end

      def flush
        @io.flush if @io
      end

      def close
        @io.close
        @io = nil
      end

      def compact(index)
        flush

        offsets = index.invert

        new_index = {}
        File.open(tmp_filename, File::RDWR | File::CREAT | File::BINARY, 0o644) do |new_io|
          @io.seek(0)
          loop do
            break if @io.eof?

            offset_old = @io.pos
            offset_new = new_io.pos

            entry_size = read_int

            if offsets.key?(offset_old)
              # write to new db
              write_int(entry_size, new_io)
              IO.copy_stream(@io, new_io, entry_size)

              # update idx
              new_index[offsets[offset_old]] = offset_new
            else
              # skip
              @io.seek(entry_size, IO::SEEK_CUR)
            end
          end
        end

        close
        FileUtils.mv(tmp_filename, @filename)
        reopen

        new_index
      end

      def add(data)
        offset = @size

        @io.seek(@size)
        write_int(data.size)
        @io.write(data)

        @size += 4 + data.size

        offset
      end

      def read_data(offset)
        @io.seek(offset)
        size = read_int
        @io.read(size)
      end

      private

      def read_int
        @io.read(4).unpack('N').first
      end

      def write_int(int, io = @io)
        if int >= 2**32
          raise ArgumentError, 'cannot write ints ≥ 2^32'
        end

        io.write([int].pack('N'))
      end

      def tmp_filename
        @filename + '.tmp'
      end
    end

    class DB
      def initialize(filename)
        @filename = filename

        @data_file = DataFile.new(db_filename)

        @index = {}
      end

      def open
        @index =
          if File.file?(index_filename)
            Marshal.load(File.read(index_filename))
          else
            {}
          end

        @data_file.open
      end

      def close
        flush
        @data_file.close
      end

      def flush
        @data_file.flush
        File.write(index_filename, Marshal.dump(@index))
      end

      def compact
        @index = @data_file.compact(@index)
      end

      def delete(key)
        @index.delete(key)
      end

      def key?(key)
        @index.key?(key)
      end

      def keys
        @index.keys
      end

      def [](key)
        offset = @index[key]
        if offset
          @data_file.read_data(offset)
        end
      end

      def []=(key, value)
        offset = @data_file.add(value)
        @index[key] = offset
      end

      private

      def db_filename
        @filename + '.db'
      end

      def index_filename
        @filename + '.idx'
      end
    end
  end
end
