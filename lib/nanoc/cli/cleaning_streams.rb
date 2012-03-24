# encoding: utf-8

module Nanoc::CLI

  module CleaningStreams

    autoload 'Abstract',   'nanoc/cli/cleaning_streams/abstract'
    autoload 'ANSIColors', 'nanoc/cli/cleaning_streams/ansi_colors'
    autoload 'UTF8',       'nanoc/cli/cleaning_streams/utf8'

  end

end
