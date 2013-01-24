usage   'sync'
summary 'sync data sources'
description <<-EOS
Sync data source data. This command is useful for updating local item caches
for data sources which rely on slow external APIs.
EOS

module Nanoc::CLI::Commands

  class Sync < ::Nanoc::CLI::CommandRunner

    def run
      # Check arguments
      if arguments.size != 0
        raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      # Make sure we are in a nanoc site directory
      self.require_site

      # Update all syncable data sources
      self.site.data_sources.each do |data_source|
        unless data_source.method(:sync).owner == Nanoc::DataSource
          puts "Syncing #{data_source.config[:type]} data source: #{data_source.items_root}"
          data_source.sync
        end
      end
    end

  end

end

runner Nanoc::CLI::Commands::Sync
