# encoding: utf-8

module Nanoc

  # Stores compiled item rep snapshots.
  class SnapshotStore

    extend Nanoc::PluginRegistry::PluginMethods

    # Fetches the content for the given snapshot.
    #
    # @param [String] item_identifier The identifier of the item
    #
    # @param [Symbol] rep_name The name of the item representation
    #
    # @param [Symbol] snapshot_name The name of the snapshot
    #
    # @return [String] The snapshot content
    def query(item_identifier, rep_name, snapshot_name)
    end

    # Sets the content for the given snapshot.
    #
    # @param [String] item_identifier The identifier of the item
    #
    # @param [Symbol] rep_name The name of the item representation
    #
    # @param [Symbol] snapshot_name The name of the snapshot
    #
    # @return [void]
    def set(item_identifier, rep_name, snapshot_name, content)
    end

    # @param [String] item_identifier The identifier of the item
    #
    # @param [Symbol] rep_name The name of the item representation
    #
    # @param [Symbol] snapshot_name The name of the snapshot
    #
    # @return [Boolean] true if content for the given snapshot exists, false otherwise
    def exist?(item_identifier, rep_name, snapshot_name)
    end

    # A snapshot store that keeps content in memory as Ruby objects.
    class InMemory < Nanoc::SnapshotStore

      identifier :in_memory

      def initialize
        @store = {}
      end

      def query(item_identifier, rep_name, snapshot_name)
        key = [ item_identifier, rep_name, snapshot_name ]
        @store.fetch(key)
      end

      def set(item_identifier, rep_name, snapshot_name, content)
        key = [ item_identifier, rep_name, snapshot_name ]
        @store[key] = content
      end

      def exist?(item_identifier, rep_name, snapshot_name)
        key = [ item_identifier, rep_name, snapshot_name ]
        @store.has_key?(key)
      end

    end

    # A snapshot store that keeps content in an in-memory SQLite3 database.
    class SQLite3 < Nanoc::SnapshotStore

      identifier :sqlite3

      def initialize
        require 'sqlite3'

        @db = ::SQLite3::Database.new ':memory:'

        @db.execute 'CREATE TABLE snapshots (item_identifier TEXT, rep_name TEXT, snapshot_name TEXT, content TEXT)'
        @db.execute 'CREATE UNIQUE INDEX snapshots_index ON snapshots (item_identifier, rep_name, snapshot_name)'
      end

      def query(item_identifier, rep_name, snapshot_name)
        query = 'SELECT content FROM snapshots WHERE item_identifier = ? AND rep_name = ? AND snapshot_name = ?'
        rows = @db.execute(query, [ item_identifier.to_s, rep_name.to_s, snapshot_name.to_s ])
        raise "No row found" if rows.empty?
        res = rows.first[0]
        res.freeze
        res
      end

      def set(item_identifier, rep_name, snapshot_name, content)
        query = 'INSERT OR REPLACE INTO snapshots (item_identifier, rep_name, snapshot_name, content) VALUES (?, ?, ?, ?)'
        @db.execute(query, [ item_identifier.to_s, rep_name.to_s, snapshot_name.to_s, content ])
      end

      def exist?(item_identifier, rep_name, snapshot_name)
        query = 'SELECT COUNT(*) FROM snapshots WHERE item_identifier = ? AND rep_name = ? AND snapshot_name = ?'
        rows = @db.execute(query, [ item_identifier.to_s, rep_name.to_s, snapshot_name.to_s ])
        rows[0][0].to_i != 0
      end

    end

  end

end
