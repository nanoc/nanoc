# encoding: utf-8

module Nanoc::CLI

  module StreamCleaners

    autoload 'Abstract',   'nanoc/cli/stream_cleaners/abstract'
    autoload 'ANSIColors', 'nanoc/cli/stream_cleaners/ansi_colors'
    autoload 'UTF8',       'nanoc/cli/stream_cleaners/utf8'

  end

end

