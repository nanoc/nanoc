module Nanoc::Int
  # Represents the site configuration.
  #
  # @api private
  class Configuration
    NONE = Object.new.freeze

    # The default configuration for a data source. A data source's
    # configuration overrides these options.
    DEFAULT_DATA_SOURCE_CONFIG =
      Hamster::Hash.new(
        type: 'filesystem',
        items_root: '/',
        layouts_root: '/',
        config: Hamster::Hash.new,
        identifier_type: 'full',
      )

    # The default configuration for a site. A site's configuration overrides
    # these options: when a {Nanoc::Int::Site} is created with a configuration
    # that lacks some options, the default value will be taken from
    # `DEFAULT_CONFIG`.
    DEFAULT_CONFIG =
      Hamster::Hash.new(
        text_extensions: %w( adoc asciidoc atom css erb haml htm html js less markdown md php rb sass scss txt xhtml xml coffee hb handlebars mustache ms slim rdoc ).sort,
        lib_dirs: %w( lib ),
        commands_dirs: %w( commands ),
        output_dir: 'output',
        data_sources: [Hamster::Hash.new],
        index_filenames: ['index.html'],
        enable_output_diff: false,
        prune: Hamster::Hash.new(auto_prune: false, exclude: ['.git', '.hg', '.svn', 'CVS']),
        string_pattern_type: 'glob',
      )

    # Creates a new configuration with the given hash.
    #
    # @param [Hash] hash The actual configuration hash
    def initialize(hash = Hamster::Hash.new)
      @wrapped = hash.__nanoc_hamsterize
    end

    def with_defaults
      self.class.new(
        DEFAULT_CONFIG
          .merge(@wrapped)
          .put(:data_sources) { |dss| dss.map { |ds| DEFAULT_DATA_SOURCE_CONFIG.merge(ds) } },
      )
    end

    def to_h
      @wrapped
    end

    def key?(key)
      @wrapped.key?(key)
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
      @wrapped = @wrapped.put(key, value)
      value
    end

    def merge(hash)
      self.class.new(@wrapped.merge(hash.to_h))
    end

    def without(key)
      self.class.new(@wrapped.reject { |k, _v| k == key })
    end

    def update(hash)
      hash.each_pair do |key, value|
        @wrapped = @wrapped.put(key, value)
      end
      self
    end

    def each
      @wrapped.each { |k, v| yield(k, v) }
      self
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
