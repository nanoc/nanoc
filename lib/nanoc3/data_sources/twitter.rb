# encoding: utf-8

module Nanoc3::DataSources

  # Nanoc3::DataSources::Twitter provides tweets from a single user as items
  # (Nanoc3::Item instances).
  #
  # The configuration must have a "username" attribute containing the username
  # of the account from which to fetch the tweets.
  #
  # The items returned by this data source will be mounted at {root}/{id},
  # where +id+ is the unique identifier of the tweet.
  #
  # The items returned by this data source will have the following attributes:
  #
  # +:created_at+:: The timestamp when this tweet was posted (a string).
  #
  # +source+:: The client used to tweet this message (HTML-encoded).
  class Twitter < Nanoc3::DataSource

    def items
      @item ||= begin
        require 'json'
        require 'time'
        require 'enumerator'

        # Get data
        @http_client ||= Nanoc3::Extra::CHiCk::Client.new
        status, headers, data = *@http_client.get("http://twitter.com/statuses/user_timeline/#{self.config[:username]}.json")

        # Parse as JSON
        raw_items = JSON.parse(data)

        # Convert to items
        raw_items.enum_with_index.map do |raw_item, i|
          # Get data
          content = raw_item['text']
          attributes = {
            :created_at  => raw_item['created_at'],
            :source      => raw_item['source']
            # TODO add more
          }
          identifier = "/#{raw_item['id']}/"
          mtime = Time.parse(raw_item['created_at'])

          # Build item
          Nanoc3::Item.new(content, attributes, identifier, mtime)
        end
      end
    end

  end

end
