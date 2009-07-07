# encoding: utf-8

module Nanoc3::DataSources

  # The Nanoc3::DataSources::FilesystemCommon module provides code
  # snippet-loading and rule-loading methods that are used by both the
  # filesystem and the filesystem_combined data sources.
  module FilesystemCommon

    def code_snippets
      Dir['lib/**/*.rb'].sort.map do |filename|
        Nanoc3::CodeSnippet.new(
          File.read(filename),
          filename.sub(/^lib\//, ''),
          File.stat(filename).mtime
        )
      end
    end

  end

end
