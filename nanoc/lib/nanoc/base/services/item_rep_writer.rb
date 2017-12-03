# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class ItemRepWriter
    TMP_TEXT_ITEMS_DIR = 'text_items'

    def write_all(item_rep, snapshot_repo)
      written_paths = Set.new

      item_rep.snapshot_defs.map(&:name).each do |snapshot_name|
        write(item_rep, snapshot_repo, snapshot_name, written_paths)
      end
    end

    def write(item_rep, snapshot_repo, snapshot_name, written_paths)
      item_rep.raw_paths.fetch(snapshot_name, []).each do |raw_path|
        write_single(item_rep, snapshot_repo, snapshot_name, raw_path, written_paths)
      end
    end

    def write_single(item_rep, snapshot_repo, snapshot_name, raw_path, written_paths)
      # Don’t write twice
      # TODO: test written_paths behavior
      return if written_paths.include?(raw_path)
      written_paths << raw_path

      # Create parent directory
      FileUtils.mkdir_p(File.dirname(raw_path))

      # Check if file will be created
      is_created = !File.file?(raw_path)

      # Notify
      Nanoc::Int::NotificationCenter.post(
        :will_write_rep, item_rep, raw_path
      )

      content = snapshot_repo.get(item_rep, snapshot_name)
      if content.binary?
        temp_path = content.filename
      else
        temp_path = temp_filename
        File.write(temp_path, content.string)
      end

      # Check whether content was modified
      is_modified = is_created || !FileUtils.identical?(raw_path, temp_path)

      # Write
      FileUtils.cp(temp_path, raw_path) if is_modified

      item_rep.modified = is_modified

      # Notify
      Nanoc::Int::NotificationCenter.post(
        :rep_written, item_rep, content.binary?, raw_path, is_created, is_modified
      )
    end

    def temp_filename
      Nanoc::Int::TempFilenameFactory.instance.create(TMP_TEXT_ITEMS_DIR)
    end
  end
end
