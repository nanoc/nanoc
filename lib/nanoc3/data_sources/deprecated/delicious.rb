# encoding: utf-8

module Nanoc3::DataSources

  # @deprecated Fetch data from online data sources manually instead
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
