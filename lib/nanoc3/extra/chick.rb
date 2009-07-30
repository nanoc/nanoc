require 'net/http'
require 'rack'
require 'rack/cache'

module Nanoc3::Extra

  # CHiCk is a caching HTTP client that uses Rack::Cache.
  module CHiCk

    # CHiCk::Client provides a simple API for issuing HTTP requests.
    class Client

      DEFAULT_OPTIONS = {
        :cache => {
          :metastore   => 'file:tmp/rack/cache.meta', 
          :entitystore => 'file:tmp/rack/cache.body'
        },
        :cache_controller => {
          :max_age => 60
        }
      }

      def initialize(options={})
        # Get options
        @options = DEFAULT_OPTIONS.merge(options)
        @options[:cache] = DEFAULT_OPTIONS[:cache].merge(@options[:cache])
        @options[:cache_controller] = DEFAULT_OPTIONS[:cache_controller].merge(@options[:cache_controller])
      end

      def get(url)
        # Build app
        options = @options
        @app ||= Rack::Builder.new {
          use Rack::Cache, options[:cache]
          use Nanoc3::Extra::CHiCk::CacheController, options[:cache_controller]
          run Nanoc3::Extra::CHiCk::RackClient
        }

        # Build environment for request
        env = Rack::MockRequest.env_for(url, :method => 'GET')

        # Debug
        puts "[CHiCk] Fetching #{url} from cache" if $DEBUG

        # Fetch
        status, headers, body_parts = @app.call(env)
        body = ''
        body_parts.each { |part| body << part }
        [ status, headers, body ]
      end

    end

    # CHiCk::CacheController sets the Cache-Control header (and more
    # specifically, max-age) to limit the number of necessary requests.
    class CacheController

      def initialize(app, options={})
        @app = app
        @options = options
      end

      def call(env)
        res = @app.call(env)
        unless res[1].has_key?('Cache-Control') || res[1].has_key?('Expires')
          res[1]['Cache-Control'] = "max-age=#{@options[:max_age]}"
        end
        res
      end

    end

    # CHiCk::RackClient performs the actual HTTP requests. It does not perform
    # any caching.
    class RackClient

      METHOD_TO_CLASS_MAPPING = {
        'DELETE'  => Net::HTTP::Delete,
        'GET'     => Net::HTTP::Get,
        'HEAD'    => Net::HTTP::Head,
        'POST'    => Net::HTTP::Post,
        'PUT'     => Net::HTTP::Put
      }

      def self.call(env)
        # Build request
        request = Rack::Request.new(env)

        # Build headers and strip HTTP_
        request_headers = env.inject({}) do |m,(k,v)|
          k =~ /^HTTP_(.*)$/ && v ? m.merge($1.gsub(/_/, '-') => v) : m
        end

        # Debug
        puts "[CHiCk] Fetching #{request.url} from the internets (not cached)" if $DEBUG

        # Build Net::HTTP request
        http = Net::HTTP.new(request.host, request.port)
        net_http_request_class = METHOD_TO_CLASS_MAPPING[request.request_method]
        raise ArgumentError, "Unsupported method: #{request.request_method}" if net_http_request_class.nil?
        net_http_request = net_http_request_class.new(request.fullpath, request_headers)
        net_http_request.body = env['rack.input'].read if [ 'POST', 'PUT' ].include?(request.request_method)

        # Perform request
        http.request(net_http_request) do |response|
          # Build Rack response triplet
          return [
            response.code.to_i,
            response.to_hash.inject({}) { |m,(k,v)| m.merge(k => v[0]) },
            [ response.body ]
          ]
        end
      end

    end

  end

end
