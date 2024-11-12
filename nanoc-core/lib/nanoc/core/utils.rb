# frozen_string_literal: true

# .sub(/^[A-Z]:/,'')

module Nanoc
  module Core
    # Utilities that don’t fit anywhere else.
    #
    # @api private
    module Utils
      # Same as File.expand_path, but does not add a drive identifier on
      # Windows. This is necessary in case the path is a Nanoc path, rather than
      # a filesystem path.
      def self.expand_path_without_drive_identifier(file_name, dir_string)
        res = File.expand_path(file_name, dir_string)

        if windows_fs?
          # On Windows, strip the drive identifier, e.g. `C:`.
          res = res.sub(/^[A-Z]:/, '')
        end

        res
      end

      # Returns `true` if absolute file paths start with a drive identifier, like `C:`.
      def self.windows_fs?
        # NOTE: This isn’t memoized with ||= because @_windows_fs is a boolean.

        return @_windows_fs if defined?(@_windows_fs)

        absolute_path = File.expand_path('/a')
        @_windows_fs = absolute_path.start_with?(/^[A-Z]:/)

        @_windows_fs
      end
    end
  end
end
