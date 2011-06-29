# encoding: utf-8

module Nanoc::DataSources

  # @deprecated Fetch data from online data sources manually instead
  class Twitter < Nanoc::DataSource

    def items
      @item ||= begin
        require 'json'

        # Get data
        @http_client ||= Nanoc::Extra::CHiCk::Client.new
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
          }
          identifier = "/#{raw_item['id']}/"
          mtime = Time.parse(raw_item['created_at'])

          # Build item
          Nanoc::Item.new(content, attributes, identifier, mtime)
        end
      end
    end

  end

end
