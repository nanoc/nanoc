# encoding: utf-8

module Nanoc::Extra::Checking::Checks
  # A check that verifies HTML files do not reference external resources with
  # URLs that would trigger "mixed content" warnings.
  #
  # @api private
  class MixedContent < ::Nanoc::Extra::Checking::Check
    PROTOCOL_PATTERN = /^(\w+):\/\//

    def run
      filenames = output_filenames.select { |f| File.extname(f) == '.html' }
      resource_uris_with_filenames = ::Nanoc::Extra::LinkCollector.new(filenames).filenames_per_resource_uri

      resource_uris_with_filenames.each_pair do |uri, fns|
        next unless guaranteed_insecure?(uri)
        fns.each do |filename|
          add_issue(
            "mixed content include: #{uri}",
            subject: filename)
        end
      end
    end

    private

    def guaranteed_insecure?(href)
      protocol = PROTOCOL_PATTERN.match(href)

      protocol && protocol[1].downcase == 'http'
    end
  end
end
