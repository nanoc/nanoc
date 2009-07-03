# encoding: utf-8

module Nanoc3

  # A Nanoc3::Config holds the site configuration. It consists of a hash and
  # the configuration file's modification time, used for determining whether
  # all items should be recompiled (because a changed configuration may need a
  # full site recompilation).
  class Config

    # The default configuration for a site. A site's configuration overrides
    # these options: when a Nanoc3::Site is created with a configuration that
    # lacks some options, the default value will be taken from
    # +DEFAULT_CONFIG+.
    DEFAULT_CONFIG = {
      :output_dir       => 'output',
      :data_source      => 'filesystem',
      :index_filenames  => [ 'index.html' ]
    }

    # The time when the site configuration was last modified.
    attr_reader :mtime

    # Creates a new configuration with the given hash containing the key/value
    # configuration pairs, and with mtime as the modification time of the
    # configuration.
    def initialize(hash, mtime=nil)
      @hash = DEFAULT_CONFIG.merge(hash.symbolize_keys)
      @mtime = mtime
    end

    # Returns the configuration value for the given key.
    def [](key)
      @hash[key]
    end

  end

end
