# encoding: utf-8

module Nanoc

  # Loads sites.
  #
  # @api private
  class SiteLoader

    # The default configuration for a data source. A data source's
    # configuration overrides these options.
    DEFAULT_DATA_SOURCE_CONFIG = {
      :type            => 'filesystem',
      :items_root      => '/',
      :layouts_root    => '/',
      :text_extensions => %w( css erb haml htm html js less markdown md php rb sass scss txt xhtml xml coffee hb handlebars mustache ms slim ).sort
    }

    # The default configuration for a site. A site's configuration overrides
    # these options: when a {Nanoc::Site} is created with a configuration
    # that lacks some options, the default value will be taken from
    # `DEFAULT_CONFIG`.
    DEFAULT_CONFIG = {
      :output_dir         => 'output',
      :data_sources       => [ {} ],
      :index_filenames    => [ 'index.html' ],
      :enable_output_diff => false,
      :prune              => { :auto_prune => false, :exclude => [ '.git', '.hg', '.svn', 'CVS' ] }
    }

    # @return [Nanoc::Site] A new site based on the current working directory
    def load
      # Load
      self.config
      self.code_snippets
      self.data_sources
      self.data_sources.each { |ds| ds.use }
      self.items
      self.layouts
      self.data_sources.each { |ds| ds.unuse }

      # Build site
      Nanoc::Site.new(
        :data_sources  => self.data_sources,
        :items         => self.items,
        :layouts       => self.layouts,
        :code_snippets => self.code_snippets,
        :config        => self.config)
    end

    # @return [Boolean] true if the current working directory is a nanoc site, false otherwise
    #
    # @api private
    def self.cwd_is_nanoc_site?
      !self.config_filename_for_cwd.nil?
    end

    # @return [String] filename of the nanoc config file in the current working directory, or nil if there is none
    #
    # @api private
    def self.config_filename_for_cwd
      filenames = %w( nanoc.yaml config.yaml )
      filenames.find { |f| File.file?(f) }
    end

  protected

    # Returns the data sources for this site. Will create a new data source if
    # none exists yet.
    #
    # @return [Array<Nanoc::DataSource>] The list of data sources for this
    #   site
    #
    # @raise [Nanoc::Errors::UnknownDataSource] if the site configuration
    #   specifies an unknown data source
    def data_sources
      @data_sources ||= begin
        config[:data_sources].map do |data_source_hash|
          # Get data source class
          data_source_class = Nanoc::DataSource.named(data_source_hash[:type])
          raise Nanoc::Errors::UnknownDataSource.new(data_source_hash[:type]) if data_source_class.nil?

          # Create data source
          data_source_class.new(
            self,
            data_source_hash[:items_root],
            data_source_hash[:layouts_root],
            data_source_hash.merge(data_source_hash[:config] || {})
          )
        end
      end
    end

    def code_snippets
      @_code_snippets ||= begin
        snippets = Dir['lib/**/*.rb'].sort.map do |filename|
          Nanoc::CodeSnippet.new(
            File.read(filename),
            filename
          ).tap { | cs| cs.load }
        end
      end
    end

    def items
      @_items ||= begin
        array = Nanoc::ItemArray.new
        data_sources.each do |ds|
          items_in_ds = ds.items
          items_in_ds.each do |i|
            i.identifier = i.identifier.prefix(ds.items_root)
            i.site = self
          end
          array.concat(items_in_ds)
        end
        array
      end
    end

    def layouts
      @_layouts ||= begin
        data_sources.flat_map do |ds|
          layouts_in_ds = ds.layouts
          layouts_in_ds.each do |i|
            i.identifier = i.identifier.prefix(ds.layouts_root)
          end
        end
      end
    end

    def config
      @_config ||= begin
        # Find config file
        filename = self.class.config_filename_for_cwd
        if filename.nil?
          raise Nanoc::Errors::GenericTrivial,
            'Could not find nanoc.yaml or config.yaml in the current working directory'
        end

        # Load
        config = YAML.load_file(filename).symbolize_keys_recursively
        config = DEFAULT_CONFIG.merge(config)
        config[:data_sources] = config[:data_sources].map do |dsc|
          DEFAULT_DATA_SOURCE_CONFIG.merge(dsc)
        end

        # Convert to proper configuration
        Nanoc::Configuration.new(config)
      end
    end

  end

end
