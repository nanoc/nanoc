# encoding: utf-8

module Nanoc

  # The in-memory representation of a nanoc site. It holds references to the
  # following site data:
  #
  # * {#items}         — the list of items         ({Nanoc::Item})
  # * {#layouts}       — the list of layouts       ({Nanoc::Layout})
  # * {#code_snippets} — the list of code snippets ({Nanoc::CodeSnippet})
  # * {#data_sources}  — the list of data sources  ({Nanoc::DataSource})
  #
  # In addition, each site has a {#config} hash which stores the site
  # configuration.
  #
  # The physical representation of a {Nanoc::Site} is usually a directory
  # that contains a configuration file, site data, a rakefile, a rules file,
  # etc. The way site data is stored depends on the data source.
  class Site

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

    attr_reader :config
    attr_reader :code_snippets
    attr_reader :data_sources
    attr_reader :items
    attr_reader :layouts

    def initialize(data)
      @config        = data.fetch(:config)
      @code_snippets = data.fetch(:code_snippets)
      @data_sources  = data.fetch(:data_sources)
      @items         = data.fetch(:items)
      @layouts       = data.fetch(:layouts)
      # TODO freeze
    end

    # TODO remove
    def compile
      compiler.run
    end

    # TODO remove
    def compiler
      @compiler ||= Compiler.new(self)
    end

    # Prevents all further modifications to itself, its items, its layouts etc.
    #
    # @return [void]
    def freeze
      config.freeze_recursively
      items.each         { |i|  i.freeze  }
      layouts.each       { |l|  l.freeze  }
      code_snippets.each { |cs| cs.freeze }
    end

  end

end
