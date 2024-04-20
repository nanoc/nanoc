# frozen_string_literal: true

module ::Nanoc
  module Checking
    class LinkCollector
      # HTML5 element attributes
      URI_ATTRS = {
        'a' => %i[href ping],
        'area' => %i[href ping],
        'audio' => %i[src],
        'base' => %i[href],
        'blockquote' => %i[cite],
        'form' => %i[action],
        'iframe' => %i[src],
        'img' => %i[src srcset],
        'link' => %i[href],
        'object' => %i[data],
        'script' => %i[src],
        'source' => %i[src srcset],
        'video' => %i[poster src],
      }.freeze
      # HTML+RDFa global URI attributes
      GLOBAL_ATTRS = %i[about resource].freeze

      def initialize(filenames, mode = nil)
        @filenames = filenames
        @filter =
          case mode
          when nil
            ->(_h) { true }
          when :external
            ->(h) { external_href?(h) }
          when :internal
            ->(h) { internal_href?(h) }
          else
            raise ArgumentError, 'Expected mode argument to be :internal, :external or nil'
          end
      end

      def filenames_per_href
        grouped_filenames { |filename| hrefs_in_file(filename) }
      end

      def filenames_per_resource_uri
        grouped_filenames { |filename| resource_uris_in_file(filename) }
      end

      def external_href?(href)
        return false if internal_href?(href)

        href =~ %r{^(//|[a-z-]+:)}
      end

      def internal_href?(href)
        return false if href.nil?

        href.start_with?('file:/')
      end

      # all links
      def hrefs_in_file(filename)
        uris_in_file filename, nil
      end

      # embedded resources, used by the mixed-content checker
      def resource_uris_in_file(filename)
        uris_in_file filename, %w[audio base form iframe img link object script source video]
      end

      private

      def grouped_filenames
        require 'nokogiri'
        grouped_filenames = {}
        @filenames.each do |filename|
          yield(filename).each do |resouce_uri|
            grouped_filenames[resouce_uri] ||= Set.new
            grouped_filenames[resouce_uri] << filename
          end
        end
        grouped_filenames
      end

      def uris_in_file(filename, tag_names)
        uris = Set.new
        # FIXME: escape is hacky
        base_uri = URI("file://#{filename.gsub(' ', '%20')}")
        doc = Nokogiri::HTML(::File.read(filename))
        doc.traverse do |tag|
          next unless tag_names.nil? || tag_names.include?(tag.name)

          attrs = []
          attrs += URI_ATTRS[tag.name] unless URI_ATTRS[tag.name].nil?
          attrs += GLOBAL_ATTRS if tag_names.nil?
          next if attrs.nil?

          attrs.each do |attr_name|
            next if tag[attr_name].nil?

            if attr_name == :srcset
              uris = uris.merge(tag[attr_name].split(',').map { |v| v.strip.split[0].strip }.compact)
            elsif %i[about ping resource].include?(attr_name)
              uris = uris.merge(tag[attr_name].split.map(&:strip).compact)
            else
              uris << tag[attr_name.to_s]
            end
          end
        end

        # Strip fragment
        uris.map! { |uri| uri.gsub(/#.*$/, '') }

        # Resolve paths relative to the filename, return invalid URIs as-is
        uris.map! do |uri|
          if uri.start_with?('//')
            # Don’t modify protocol-relative URLs. They’re absolute!
            uri
          else
            begin
              # FIXME: escape is hacky
              URI.join(base_uri, uri.gsub(' ', '%20')).to_s
            rescue
              uri
            end
          end
        end

        uris.select(&@filter)
      end
    end
  end
end
