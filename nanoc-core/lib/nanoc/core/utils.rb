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

        if Nanoc::Core.on_windows?
          # On Windows, strip the drive identifier, e.g. `C:`.
          res = res.sub(/^[A-Z]:/, '')
        end

        res
      end
    end
  end
end
