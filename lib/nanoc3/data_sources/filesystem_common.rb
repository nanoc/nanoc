# encoding: utf-8

module Nanoc3::DataSources

  # The Nanoc3::DataSources::FilesystemCommon module provides code- and
  # rule-loading methods that are used by both the filesystem and the
  # filesystem_combined data sources.
  module FilesystemCommon

    def code
      # Get files
      filenames = Dir['lib/**/*.rb'].sort

      # Read snippets
      snippets = filenames.map do |fn|
        { :filename => fn, :code => File.read(fn) }
      end

      # Get modification time
      mtimes = filenames.map { |filename| File.stat(filename).mtime }
      mtime = mtimes.inject { |memo, mtime| memo > mtime ? mtime : memo }

      # Build code
      Nanoc3::Code.new(snippets, mtime)
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
