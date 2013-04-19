# encoding: utf-8

module Nanoc

  class ItemRepWriter

    # Writes the item rep's compiled content to the rep's output file.
    #
    # This method will send two notifications: one before writing the item
    # representation, and one after. These notifications can be used for
    # generating diffs, for example.
    #
    # @param [Nanoc::ItemRep] rep The item rep to write
    #
    # @param [Symbol, nil] snapshot The name of the snapshot to write.
    #
    # @return [void]
    def write(rep, snapshot=:last)
      # Get raw path
      raw_path = rep.raw_path(:snapshot => snapshot)
      return if raw_path.nil?

      # Create parent directory
      FileUtils.mkdir_p(File.dirname(raw_path))

      # Check if file will be created
      is_created = !File.file?(raw_path)

      # Notify
      Nanoc::NotificationCenter.post(:will_write_rep, rep, snapshot)

      if rep.binary?
        temp_path = rep.temporary_filenames[:last]
      else
        temp_path = self.temp_filename
        File.open(temp_path, 'w') do |io|
          io.write(rep.stored_content_at_snapshot(:last))
        end
      end

      # Check whether content was modified
      is_modified = is_created || !FileUtils.identical?(raw_path, temp_path)

      # Write
      FileUtils.cp(temp_path, raw_path) if is_modified

      # Notify
      Nanoc::NotificationCenter.post(:rep_written, rep, raw_path, is_created, is_modified)
    end

    TMP_TEXT_ITEMS_DIR = 'tmp/text_items'

    def temp_filename
      FileUtils.mkdir_p(TMP_TEXT_ITEMS_DIR)
      tempfile = Tempfile.new('', TMP_TEXT_ITEMS_DIR)
      new_filename = tempfile.path
      tempfile.close!

      File.expand_path(new_filename)
    end

  end

end
