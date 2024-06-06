# frozen_string_literal: true

module Nanoc
  module Core
    # Represents the site configuration.
    class Configuration
      include Nanoc::Core::ContractsSupport

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
      # these options: when a {Nanoc::Core::Site} is created with a configuration
      # that lacks some options, the default value will be taken from
      # `DEFAULT_CONFIG`.
      DEFAULT_CONFIG = {
        text_extensions: %w[adoc asciidoc atom css erb haml htm html js less markdown md org php rb sass scss tex txt xhtml xml coffee hb handlebars mustache ms slim rdoc].sort,
        lib_dirs: %w[lib],
        commands_dirs: %w[commands],
        output_dir: 'output',
        data_sources: [{}],
        index_filenames: ['index.html'],
        enable_output_diff: false,
        prune: { auto_prune: false, exclude: ['.git', '.hg', '.svn', 'CVS'] },
        string_pattern_type: 'glob',
        action_provider: 'rule_dsl',
      }.freeze

      # @return [String, nil] The active environment for the configuration
      attr_reader :env_name

      contract C::None => C::AbsolutePathString
      attr_reader :dir

      # Configuration environments property key
      ENVIRONMENTS_CONFIG_KEY = :environments
      NANOC_ENV = 'NANOC_ENV'
      NANOC_ENV_DEFAULT = 'default'

      contract C::KeywordArgs[hash: C::Optional[Hash], env_name: C::Maybe[String], dir: C::AbsolutePathString] => C::Any
      def initialize(dir:, hash: {}, env_name: nil)
        @env_name = env_name
        @wrapped = hash.__nanoc_symbolize_keys_recursively
        @dir = dir

        validate
      end

      contract C::None => self
      def with_defaults
        new_wrapped = DEFAULT_CONFIG.merge(@wrapped)
        new_wrapped[:data_sources] = new_wrapped[:data_sources].map do |ds|
          DEFAULT_DATA_SOURCE_CONFIG.merge(ds)
        end

        self.class.new(hash: new_wrapped, dir: @dir, env_name: @env_name)
      end

      def with_environment
        return self unless @wrapped.key?(ENVIRONMENTS_CONFIG_KEY)

        # Set active environment
        env_name = @env_name || ENV.fetch(NANOC_ENV, NANOC_ENV_DEFAULT)

        # Load given environment configuration
        env_config = @wrapped[ENVIRONMENTS_CONFIG_KEY].fetch(env_name.to_sym, {})

        self.class.new(hash: @wrapped, dir: @dir, env_name:).merge(env_config)
      end

      contract C::None => Hash
      def to_h
        @wrapped
      end

      # For compat
      contract C::None => Hash
      def attributes
        to_h
      end

      contract C::Any => C::Bool
      def key?(key)
        @wrapped.key?(key)
      end

      contract C::Any => C::Any
      def [](key)
        @wrapped[key]
      end

      contract C::Args[C::Any] => C::Any
      def dig(*keys)
        @wrapped.dig(*keys)
      end

      contract C::Any, C::Maybe[C::Any], C::Maybe[C::Func[C::None => C::Any]] => C::Any
      def fetch(key, fallback = Nanoc::Core::UNDEFINED, &)
        @wrapped.fetch(key) do
          if !Nanoc::Core::UNDEFINED.equal?(fallback)
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

      contract C::Or[Hash, self] => self
      def merge(hash)
        self.class.new(hash: merge_recursively(@wrapped, hash.to_h), dir: @dir, env_name: @env_name)
      end

      contract C::Any => self
      def without(key)
        self.class.new(hash: @wrapped.reject { |k, _v| k == key }, dir: @dir, env_name: @env_name)
      end

      contract C::Any => self
      def update(hash)
        @wrapped.update(hash)
        self
      end

      contract C::Func[C::Any, C::Any => C::Any] => self
      def each(&)
        @wrapped.each(&)
        self
      end

      contract C::None => self
      def freeze
        super
        @wrapped.__nanoc_freeze_recursively
        self
      end

      contract C::None => C::AbsolutePathString
      def output_dir
        make_absolute(self[:output_dir]).freeze
      end

      contract C::None => Symbol
      def action_provider
        self[:action_provider].to_sym
      end

      contract C::None => C::IterOf[C::AbsolutePathString]
      def output_dirs
        envs = @wrapped.fetch(ENVIRONMENTS_CONFIG_KEY, {})
        res = [output_dir] + envs.values.map { |v| make_absolute(v[:output_dir]) }
        res.uniq.compact
      end

      # Returns an object that can be used for uniquely identifying objects.
      #
      # @return [Object] An unique reference to this object
      def reference
        'configuration'
      end

      def inspect
        "<#{self.class}>"
      end

      contract C::None => C::Num
      def hash
        [@dir, @env_name].hash
      end

      contract C::Any => C::Bool
      def ==(other)
        eql?(other)
      end

      contract C::Any => C::Bool
      def eql?(other)
        other.is_a?(self.class) && @dir == other.dir && @env_name == other.env_name
      end

      private

      def make_absolute(path)
        path && @dir && File.absolute_path(path, @dir).encode('UTF-8')
      end

      def merge_recursively(config1, config2)
        config1.merge(config2) do |_, value1, value2|
          if value1.is_a?(Hash) && value2.is_a?(Hash)
            merge_recursively(value1, value2)
          else
            value2
          end
        end
      end

      def validate
        dir = File.dirname(__FILE__)
        schema_data = JSON.parse(File.read(dir + '/configuration-schema.json'))
        schema = JsonSchema.parse!(schema_data)
        schema.expand_references!
        schema.validate!(@wrapped.__nanoc_stringify_keys_recursively)
      end
    end
  end
end
