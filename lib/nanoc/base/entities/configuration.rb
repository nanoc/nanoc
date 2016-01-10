module Nanoc::Int
  # Represents the site configuration.
  #
  # @api private
  class Configuration
    NONE = Object.new

    # The default configuration for a data source. A data source's
    # configuration overrides these options.
    DEFAULT_DATA_SOURCE_CONFIG = {
      type: 'filesystem',
      items_root: '/',
      layouts_root: '/',
      config: {},
      identifier_type: 'full',
    }

    # The default configuration for a site. A site's configuration overrides
    # these options: when a {Nanoc::Int::Site} is created with a configuration
    # that lacks some options, the default value will be taken from
    # `DEFAULT_CONFIG`.
    DEFAULT_CONFIG = {
      text_extensions: %w( adoc asciidoc atom css erb haml htm html js less markdown md php rb sass scss txt xhtml xml coffee hb handlebars mustache ms slim rdoc ).sort,
      lib_dirs: %w( lib ),
      commands_dirs: %w( commands ),
      output_dir: 'output',
      data_sources: [{}],
      index_filenames: ['index.html'],
      enable_output_diff: false,
      prune: { auto_prune: false, exclude: ['.git', '.hg', '.svn', 'CVS'] },
      string_pattern_type: 'glob',
    }

    # Creates a new configuration with the given hash.
    #
    # @param [Hash] hash The actual configuration hash
    def initialize(hash = {})
      @wrapped = hash.__nanoc_symbolize_keys_recursively
    end

    def with_defaults
      new_wrapped = DEFAULT_CONFIG.merge(@wrapped)
      new_wrapped[:data_sources] = new_wrapped[:data_sources].map do |ds|
        DEFAULT_DATA_SOURCE_CONFIG.merge(ds)
      end

      self.class.new(new_wrapped)
    end

    def to_h
      @wrapped
    end

    def [](key)
      @wrapped[key]
    end

    def fetch(key, fallback = NONE, &_block)
      @wrapped.fetch(key) do
        if !fallback.equal?(NONE)
          fallback
        elsif block_given?
          yield(key)
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
    end

    def []=(key, value)
      @wrapped[key] = value
    end

    def merge(hash)
      self.class.new(@wrapped.merge(hash.to_h))
    end

    def without(key)
      self.class.new(@wrapped.reject { |k, _v| k == key })
    end

    def update(hash)
      @wrapped.update(hash)
    end

    def each
      @wrapped.each { |k, v| yield(k, v) }
      self
    end

    def freeze
      super
      @wrapped.__nanoc_freeze_recursively
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @return [Object] An unique reference to this object
    def reference
      :config
    end

    def inspect
      "<#{self.class}>"
    end
  end
end
