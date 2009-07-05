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

    def rules
      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc3::Errors::NoRulesFileFound.new if rules_filename.nil?

      # Get data to return
      rules = File.read(rules_filename)
      mtime = File.stat(rules_filename).mtime

      # Done
      [ rules, mtime ]
    end

  end

end
