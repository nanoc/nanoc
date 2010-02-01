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

    # Finds all items/layouts/... in the given base directory. Returns a hash
    # in which the keys are the file's dirname + basenames, and the values a
    # pair consisting of the metafile extension and the content file
    # extension. The meta file extension or the content file extension can be
    # nil, but not both. Backup files are ignored. For example:
    #
    #   {
    #     'content/foo' => [ 'yaml', 'html' ],
    #     'content/bar' => [ 'yaml', nil    ],
    #     'content/qux' => [ nil,    'html' ]
    #   }
    def all_split_files_in(dir_name)
      # Get all good file names
      filenames = Dir[dir_name + '/**/*'].select { |i| File.file?(i) }
      filenames.reject! { |fn| fn =~ /(~|\.orig|\.rej|\.bak)$/ }

      # Group by identifier
      grouped_filenames = filenames.group_by { |fn| basename_of(fn) }

      # Convert values into metafile/content file extension tuple
      grouped_filenames.each_pair do |key, filenames|
        # Divide
        meta_filenames    = filenames.select { |fn| ext_of(fn) == '.yaml' }
        content_filenames = filenames.select { |fn| ext_of(fn) != '.yaml' }

        # Check number of files per type
        if ![ 0, 1 ].include?(meta_filenames.size)
          raise RuntimeError, "Found #{meta_filenames.size} meta files for #{key}; expected 0 or 1"
        end
        if ![ 0, 1 ].include?(content_filenames.size)
          raise RuntimeError, "Found #{content_filenames.size} content files for #{key}; expected 0 or 1"
        end

        # Reorder elements and convert to extnames
        filenames[0] = meta_filenames[0]    ? ext_of(meta_filenames[0])[1..-1]    : nil
        filenames[1] = content_filenames[0] ? ext_of(content_filenames[0])[1..-1] : nil
      end

      # Done
      grouped_filenames
    end

    # Returns the base name of filename, i.e. filename with the first or all
    # extensions stripped off. By default, all extensions are stripped off,
    # but when allow_periods_in_identifiers is set to true in the site
    # configuration, only the last extension will be stripped .
    def basename_of(filename)
      filename.sub(extension_regex, '')
    end

    # Returns the extension(s) of filename. Supports multiple extensions.
    # Includes the leading period.
    def ext_of(filename)
      filename =~ extension_regex ? $1 : ''
    end

    # Returns a regex that is used for determining the extension of a file
    # name. The first match group will be the entire extension, including the
    # leading period.
    def extension_regex
      if @config && @config[:allow_periods_in_identifiers]
        /(\.[^\/\.]+$)/
      else
        /(\.[^\/]+$)/
      end
    end

  end

end
