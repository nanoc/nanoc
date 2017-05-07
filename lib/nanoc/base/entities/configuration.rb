module Nanoc::Int
  # Represents the site configuration.
  #
  # @api private
  class Configuration
    include Nanoc::Int::ContractsSupport

    NONE = Object.new.freeze

    # The default configuration for a data source. A data source's
    # configuration overrides these options.
    DEFAULT_DATA_SOURCE_CONFIG = {
      type: 'filesystem',
      items_root: '/',
      layouts_root: '/',
      config: {},
      identifier_type: 'full',
    }.freeze

    # The default configuration for a site. A site's configuration overrides
    # these options: when a {Nanoc::Int::Site} is created with a configuration
    # that lacks some options, the default value will be taken from
    # `DEFAULT_CONFIG`.
    DEFAULT_CONFIG = {
      text_extensions: %w[adoc asciidoc atom css erb haml htm html js less markdown md php rb sass scss txt xhtml xml coffee hb handlebars mustache ms slim rdoc].sort,
      lib_dirs: %w[lib],
      commands_dirs: %w[commands],
      output_dir: 'output',
      data_sources: [{}],
      index_filenames: ['index.html'],
      enable_output_diff: false,
      prune: { auto_prune: false, exclude: ['.git', '.hg', '.svn', 'CVS'] },
      string_pattern_type: 'glob',
    }.freeze

    # @return [String, nil] The active environment for the configuration
    attr_reader :env_name

    # Configuration environments property key
    ENVIRONMENTS_CONFIG_KEY = :environments
    NANOC_ENV = 'NANOC_ENV'.freeze
    NANOC_ENV_DEFAULT = 'default'.freeze

    contract C::KeywordArgs[hash: C::Optional[Hash], env_name: C::Maybe[String]] => C::Any
    # Creates a new configuration with the given hash.
    #
    # @param [Hash] hash The actual configuration hash
    # @param [String, nil] env_name The active environment for this configuration
    def initialize(hash: {}, env_name: nil)
      @env_name = env_name
      @wrapped = hash.__nanoc_symbolize_keys_recursively
    end

    contract C::None => self
    def with_defaults
      new_wrapped = DEFAULT_CONFIG.merge(@wrapped)
      new_wrapped[:data_sources] = new_wrapped[:data_sources].map do |ds|
        DEFAULT_DATA_SOURCE_CONFIG.merge(ds)
      end

      self.class.new(hash: new_wrapped, env_name: @env_name)
    end

    def with_environment
      return self unless @wrapped.key?(ENVIRONMENTS_CONFIG_KEY)

      # Set active environment
      env_name = @env_name || ENV.fetch(NANOC_ENV, NANOC_ENV_DEFAULT)

      # Load given environment configuration
      env_config = @wrapped[ENVIRONMENTS_CONFIG_KEY].fetch(env_name.to_sym, {})

      self.class.new(hash: @wrapped, env_name: env_name).merge(env_config)
    end

    contract C::None => Hash
    def to_h
      @wrapped
    end

    contract C::Any => C::Bool
    def key?(key)
      @wrapped.key?(key)
    end

    contract C::Any => C::Any
    def [](key)
      @wrapped[key]
    end

    contract C::Any, C::Maybe[C::Any], C::Maybe[C::Func[C::None => C::Any]] => C::Any
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

    contract C::Any, C::Any => C::Any
    def []=(key, value)
      @wrapped[key] = value
    end

    def merge_recursively(c1, c2)
      c1.merge(c2) { |_, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? merge_recursively(v1, v2) : v2 }
    end
    private :merge_recursively

    contract C::Or[Hash, self] => self
    def merge(hash)
      self.class.new(hash: merge_recursively(@wrapped, hash.to_h), env_name: @env_name)
    end

    contract C::Any => self
    def without(key)
      self.class.new(hash: @wrapped.reject { |k, _v| k == key }, env_name: @env_name)
    end

    contract C::Any => self
    def update(hash)
      @wrapped.update(hash)
      self
    end

    contract C::Func[C::Any, C::Any => C::Any] => self
    def each
      @wrapped.each { |k, v| yield(k, v) }
      self
    end

    contract C::None => self
    def freeze
      super
      @wrapped.__nanoc_freeze_recursively
      self
    end

    contract C::None => String
    def output_dir
      self[:output_dir]
    end

    contract C::None => C::IterOf[String]
    def output_dirs
      envs = @wrapped.fetch(ENVIRONMENTS_CONFIG_KEY, {})
      res = [output_dir] + envs.values.map { |v| v[:output_dir] }
      res.uniq.compact
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
