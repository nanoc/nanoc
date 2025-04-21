# frozen_string_literal: true

module Nanoc
  module Core
    class ItemRepWriter
      include Nanoc::Core::ContractsSupport
      include Nanoc::Core::Assertions::Mixin

      TMP_TEXT_ITEMS_DIR = 'text_items'

      def write_all(item_rep, compiled_content_store)
        written_paths = Set.new

        item_rep.snapshot_defs.map(&:name).each do |snapshot_name|
          write(item_rep, compiled_content_store, snapshot_name, written_paths)
        end
      end

      def write(item_rep, compiled_content_store, snapshot_name, written_paths)
        item_rep.raw_paths.fetch(snapshot_name, []).each do |raw_path|
          write_single(item_rep, compiled_content_store, snapshot_name, raw_path, written_paths)
        end
      end

      def write_single(item_rep, compiled_content_store, snapshot_name, raw_path, written_paths)
        assert Nanoc::Core::Assertions::PathIsAbsolute.new(path: raw_path)

        # Don’t write twice
        # TODO: test written_paths behavior
        return if written_paths.include?(raw_path)

        written_paths << raw_path

        # Create parent directory
        FileUtils.mkdir_p(File.dirname(raw_path))

        # Check if file will be created
        is_created = !File.file?(raw_path)

        # Notify
        Nanoc::Core::NotificationCenter.post(
          :rep_write_started, item_rep, raw_path
        )

        content = compiled_content_store.get(item_rep, snapshot_name)
        if content.binary?
          temp_path = content.filename
        else
          temp_path = temp_filename
          File.write(temp_path, content.string)
        end

        # Check whether content was modified
        is_modified = is_created || !FileUtils.identical?(raw_path, temp_path)

        # Notify ready for diff generation
        if !is_created && is_modified && !content.binary?
          Nanoc::Core::NotificationCenter.post(
            :rep_ready_for_diff, raw_path, File.read(raw_path, encoding: 'UTF-8'), content.string
          )
        end

        # Write
        if is_modified
          smart_cp(temp_path, raw_path)
        end

        item_rep.modified = is_modified

        # Notify
        Nanoc::Core::NotificationCenter.post(
          :rep_write_ended, item_rep, content.binary?, raw_path, is_created, is_modified
        )
      end

      def temp_filename
        Nanoc::Core::TempFilenameFactory.instance.create(TMP_TEXT_ITEMS_DIR)
      end

      def smart_cp(from, to)
        # Try clonefile
        if defined?(Clonefile)
          FileUtils.rm_f(to)
          begin
            res = Clonefile.always(from, to)
            return if res
          rescue Clonefile::UnsupportedPlatform, Errno::ENOTSUP, Errno::EXDEV, Errno::EINVAL
          end
        end

        # Try with hardlink
        begin
          FileUtils.ln(from, to, force: true)
          return
        rescue Errno::EXDEV, Errno::EACCES
        end

        # Fall back to old-school copy
        FileUtils.cp(from, to)
      end
    end
  end
end
