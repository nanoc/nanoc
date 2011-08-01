require 'yuicompressor'

module Nanoc::Filters
  class YUICompress < Nanoc::Filter

    # Compress Javascript or CSS via YUICompressor gem.
    #
    # We set :munge true by default, which is different from the YUICompressor default,
    # but matches the YUI command line tool.
    #
    # We also set :type => 'js'  For CSS, set :type => 'css'
    #
    # @content [String] Javascript or CSS input
    # @params [Hash] Options passed to YUICompressor  q.v.
    # @return [String] compressed but equivalent Javascript oor CSS
    #
    def run(content, params = {})
      YUICompressor.compress(content, {:munge => true, :type => 'js'}.merge(params))
    end
  end
end
