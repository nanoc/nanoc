# encoding: utf-8

module Nanoc3::DataSources

  # Nanoc3::DataSources::Delicious provides for a delicious.com bookmarks from
  # a single user as items (Nanoc3::Item instances).
  #
  # The configuration must have a "username" attribute containing the username
  # of the account from which to fetch the bookmarks.
  #
  # The items returned by this data source will be mounted at {root}/{id},
  # where +id+ is a sequence number that is not necessarily unique for this
  # bookmark (because delicious.com unfortunately does not provide unique IDs
  # for each bookmark).
  #
  # The items returned by this data source will have the following attributes:
  #
  # +:url+:: The URL the bookmark leads to.
  #
  # +:description+:: The description (title, usually) of the bookmark.
  #
  # +:tags+:: An array of tags (strings) for this bookmark.
  #
  # +:date+:: The timestamp when this bookmark was created (a Time object).
  #
  # +:note+:: The personal note for this bookmark (can be nil).
  #
  # +:author+:: The username of the person storing the bookmark.
  class Delicious < Nanoc3::DataSource

    def items
      @items ||= begin
        require 'json'
        require 'time'
        require 'enumerator'

        # Get data
        @http_client ||= Nanoc3::Extra::CHiCk::Client.new
        status, headers, data = *@http_client.get("http://feeds.delicious.com/v2/json/#{self.config[:username]}")

        # Parse as JSON
        raw_items = JSON.parse(data)

        # Convert to items
        raw_items.enum_with_index.map do |raw_item, i|
          # Get data
          content = raw_item['n']
          attributes = {
            :url         => raw_item['u'],
            :description => raw_item['d'],
            :tags        => raw_item['t'],
            :date        => Time.parse(raw_item['dt']),
            :note        => raw_item['n'],
            :author      => raw_item['a']
          }
          identifier = "/#{i}/"
          mtime = nil

          # Build item
          Nanoc3::Item.new(content, attributes, identifier, mtime)
        end
      end
    end

  end

end
