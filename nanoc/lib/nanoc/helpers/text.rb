# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#text
  module Text
    # @param [String] string
    # @param [Number] length
    # @param [String] omission
    #
    # @return [String]
    def excerptize(string, length: 25, omission: '...')
      if string.length > length
        excerpt_length = [0, length - omission.length].max
        string[0...excerpt_length] + omission
      else
        string
      end
    end

    # @param [String] string
    #
    # @return [String]
    def strip_html(string)
      # FIXME: will need something more sophisticated than this, because it sucks
      string.gsub(/<[^>]*(>+|\s*\z)/m, '').strip
    end
  end
end
