module Nanoc3::Extra

  # Some interesting URLs describing client-side caching with Rack::Cache:
  #
  # * http://adam.blog.heroku.com/past/2009/4/7/clientside_caching_with_cacheability/
  # * http://github.com/halorgium/rack-client/tree/master
  # * http://gist.github.com/58095

  # Nanoc3::Extra::CachingHTTPClient is a simple HTTP client with full caching
  # support (Cache-Control (max-age), Expires, Last-Modified, ETag).
  class CachingHTTPClient

    CACHE_FILENAME = 'tmp/http.cache'

    def initialize
      require 'pstore'

      @cache = PStore.new(CACHE_FILENAME)
    end

    # Returns the data at the given URL, fetching the data from the cache if it exists.
    def get(url)
      require 'open-uri'

      # Look up data in cache
      # TODO make use of HTTP caching support
      data = nil
      @cache.transaction { data = @cache[url] }

      if data.nil?
        # Download data
        data = open(url).read
        @cache.transaction { @cache[url] = data }
      end

      # Done
      data
    end

  end

end
