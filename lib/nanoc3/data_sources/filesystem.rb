# encoding: utf-8

module Nanoc3::DataSources

  # The Nanoc3::Filesystem class is an abstract superclass for all
  # filesystem-based data sources.
  class Filesystem < Nanoc3::DataSource

    ########## VCSes ##########

    attr_accessor :vcs

    def vcs
      @vcs ||= Nanoc3::Extra::VCSes::Dummy.new
    end

    ########## Preparation ##########

    # See superclass for documentation.
    def up
    end

    # See superclass for documentation.
    def down
    end

    # See superclass for documentation.
    def setup
      # Create directories
      %w( content layouts lib ).each do |dir|
        FileUtils.mkdir_p(dir)
        vcs.add(dir)
      end
    end

    ########## Loading data ##########

    # See superclass for documentation.
    def items
      load_objects('content', 'item', Nanoc3::Item)
    end

    # See superclass for documentation.
    def layouts
      load_objects('layouts', 'layout', Nanoc3::Layout)
    end

    ########## Creating data ##########

    # See superclass for documentation.
    def create_item(content, attributes, identifier)
      create_object('content', content, attributes, identifier)
    end

    # See superclass for documentation.
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
