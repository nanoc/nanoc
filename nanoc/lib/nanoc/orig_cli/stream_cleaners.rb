# frozen_string_literal: true

# @api private
module Nanoc::OrigCLI::StreamCleaners
end

require_relative 'stream_cleaners/abstract'

require_relative 'stream_cleaners/ansi_colors'
require_relative 'stream_cleaners/utf8'
