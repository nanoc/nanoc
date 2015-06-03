module Nanoc::Int
  # @api private
  class ItemRepWriter
    TMP_TEXT_ITEMS_DIR = 'text_items'

    def write(item_rep, raw_path)
      # Create parent directory
      FileUtils.mkdir_p(File.dirname(raw_path))

      # Check if file will be created
      is_created = !File.file?(raw_path)

      # Notify
      Nanoc::Int::NotificationCenter.post(:will_write_rep, item_rep, raw_path)

      if item_rep.binary?
        temp_path = item_rep.temporary_filenames[:last]
      else
        temp_path = temp_filename
        File.write(temp_path, item_rep.content[:last])
      end

      # Check whether content was modified
      is_modified = is_created || !FileUtils.identical?(raw_path, temp_path)

      # Write
      FileUtils.cp(temp_path, raw_path) if is_modified

      # Notify
      Nanoc::Int::NotificationCenter.post(:rep_written, item_rep, raw_path, is_created, is_modified)
    end

    def temp_filename
      Nanoc::Int::TempFilenameFactory.instance.create(TMP_TEXT_ITEMS_DIR)
    end
  end
end
