# encoding: utf-8

module Nanoc3::DataSources

  # Nanoc3::DataSources::LastFM provides data about recently played tracks
  # from from a single Last.fm user as items (Nanoc3::Item instances).
  #
  # The configuration must have a "username" attribute containing the username
  # of the account from which to fetch the data, and an "api_key" attribute
  # containing the API key (which can be obtained from the Last.fm site).
  #
  # The items returned by this data source will be mounted at {root}/{id},
  # where +id+ is a sequence number that is not necessarily unique for this
  # bookmark (because delicious.com unfortunately does not provide unique IDs
  # for each track).
  #
  # The items returned by this data source will have the following attributes:
  #
  # +:name+:: The name of the track.
  #
  # +played_at+:: The timestamp when the track was played (a Time instance).
  #
  # +url+:: The Last.fm URL corresponding to the track (a String instance).
  #
  # +artist+:: A hash containing information about the track's artist.
  #
  # The +artist+ hash consists of the following keys:
  #
  # +name+:: The name of the artist.
  #
  # +url+:: The Last.fm URL corresponding to the artist (a String instance).
  class LastFM < Nanoc3::DataSource

    def items
      @items ||= begin
        require 'json'
        require 'time'
        require 'uri'
        require 'enumerator'

        # Check configuration
        if self.config[:username].nil?
          raise RuntimeError, "LastFM data source requires a username in the configuration"
        end
        if self.config[:api_key].nil?
          raise RuntimeError, "LastFM data source requires an API key in the configuration"
        end

        # Get data
        @http_client ||= Nanoc3::Extra::CHiCk::Client.new
        status, headers, data = *@http_client.get(
          'http://ws.audioscrobbler.com/2.0/' +
            '?method=user.getRecentTracks' +
            '&format=json' +
            '&user=' + URI.escape(self.config[:username]) +
            '&api_key=' + URI.escape(self.config[:api_key])
        )

        # Parse as JSON
        parsed_data = JSON.parse(data)
        raw_items = parsed_data['recenttracks']['track']

        # Convert to items
        raw_items.enum_with_index.map do |raw_item, i|
          # Get artist data
          artist_status, artist_headers, artist_data = *@http_client.get(
            'http://ws.audioscrobbler.com/2.0/' +
              '?method=artist.getInfo' +
              '&format=json' +
              (
                raw_item['artist']['mbid'].empty? ?
                '&artist=' + URI.escape(raw_item['artist']['#text']) :
                '&mbid=' + URI.escape(raw_item['artist']['mbid'])
              ) +
              '&api_key=' + URI.escape(self.config[:api_key])
          )

          # Parse as JSON
          parsed_artist_data = JSON.parse(artist_data)
          raw_artist_info = parsed_artist_data['artist']

          # Build data
          content = ''

          # Handle track dates
          if raw_item['@attr'] && raw_item['@attr']['nowplaying'] == 'true'
            track_played_at = Time.now
            now_playing = true
          else
            played_at = Time.parse(raw_item['date']['#text'])
            now_playing = false
          end
          
          attributes = {
            :name      => raw_item['name'],
            :artist    => {
              :name      => raw_artist_info['name'],
              :url       => raw_artist_info['url']
            },
            :url       => raw_item['url'],
            :played_at => track_played_at,
            :now_playing => now_playing
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
