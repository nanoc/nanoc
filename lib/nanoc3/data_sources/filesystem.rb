# encoding: utf-8

module Nanoc3::DataSources

  # Provides functionality common across all filesystem data sources.
  module Filesystem

    # The VCS that will be called when adding, deleting and moving files. If
    # no VCS has been set, or if the VCS has been set to `nil`, a dummy VCS
    # will be returned.
    #
    # @return [Nanoc3::Extra::VCS, nil] The VCS that will be used.
    def vcs
      @vcs ||= Nanoc3::Extra::VCSes::Dummy.new
    end
    attr_writer :vcs

    # See {Nanoc3::DataSource#up}.
    def up
    end

    # See {Nanoc3::DataSource#down}.
    def down
    end

    # See {Nanoc3::DataSource#setup}.
    def setup
      # Create directories
      %w( content layouts lib ).each do |dir|
        FileUtils.mkdir_p(dir)
        vcs.add(dir)
      end
    end

    # See {Nanoc3::DataSource#items}.
    def items
      load_objects('content', 'item', Nanoc3::Item)
    end

    # See {Nanoc3::DataSource#layouts}.
    def layouts
      load_objects('layouts', 'layout', Nanoc3::Layout)
    end

    # See {Nanoc3::DataSource#create_item}.
    def create_item(content, attributes, identifier)
      create_object('content', content, attributes, identifier)
    end

    # See {Nanoc3::DataSource#create_layout}.
    def create_layout(content, attributes, identifier)
      create_object('layouts', content, attributes, identifier)
    end

  private

    # Creates a new object (item or layout) on disk in dir_name according to
    # the given identifier. The file will have its attributes taken from the
    # attributes hash argument and its content from the content argument.
    def create_object(dir_name, content, attributes, identifier)
      raise NotImplementedError.new(
        "#{self.class} does not implement ##{name}"
      )
    end

    # Creates instances of klass corresponding to the files in dir_name. The
    # kind attribute indicates the kind of object that is being loaded and is
    # used solely for debugging purposes.
    def load_objects(dir_name, kind, klass)
      raise NotImplementedError.new(
        "#{self.class} does not implement ##{name}"
      )
    end

  end

end
