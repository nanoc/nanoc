require 'net/http'
require 'rack'
require 'rack/cache'

module Nanoc::Extra

  # @deprecated Use a HTTP library such as
  #   [Net::HTTP](http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/) or
  #   [Curb](http://curb.rubyforge.org/) instead.
  module CHiCk

    # @deprecated Use a HTTP library such as
    #   [Net::HTTP](http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/) or
    #   [Curb](http://curb.rubyforge.org/) instead.
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
          use Rack::Cache, options[:cache].merge(:verbose => true)
          use Nanoc::Extra::CHiCk::CacheController, options[:cache_controller]
          run Nanoc::Extra::CHiCk::RackClient
        }

        # Build environment for request
        env = Rack::MockRequest.env_for(url, :method => 'GET')

        # Fetch
        puts "[CHiCk] Fetching #{url}..." if $DEBUG
        status, headers, body_parts = @app.call(env)
        puts "[CHiCk] #{url}: #{headers['X-Rack-Cache']}" if $DEBUG

        # Join body
        body = ''
        body_parts.each { |part| body << part }

        # Done
        [ status, headers, body ]
      end

    end

    # @deprecated Use a HTTP library such as
    #   [Net::HTTP](http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/) or
    #   [Curb](http://curb.rubyforge.org/) instead.
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

    # @deprecated Use a HTTP library such as
    #   [Net::HTTP](http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/) or
    #   [Curb](http://curb.rubyforge.org/) instead.
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
