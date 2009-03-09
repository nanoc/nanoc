module Nanoc::DataSources

  # = Pages
  #
  # The filesystem data source stores its pages in nested directories. A page
  # is represented by a single file. The root directory is the 'content'
  # directory.
  #
  # The metadata for a page is embedded into the file itself. It is stored at
  # the top of the file, between '-----' (five dashes) separators. For
  # example:
  #
  #   -----
  #   filters_pre: [ 'redcloth' ]
  #   -----
  #   h1. Hello!
  #
  # The identifier of a page is determined as follows. A file with an
  # 'index.*' filename, such as 'index.txt', will have the filesystem path
  # with the 'index.*' part stripped as a identifier. For example,
  # 'foo/bar/index.html' will have '/foo/bar/' as identifier.
  #
  # A file with a filename not starting with 'index.', such as 'foo.html',
  # will have an identifier ending in 'foo/'. For example, 'foo/bar.html' will have
  # '/foo/bar/' as identifier.
  #
  # Note that it is possible for two different, separate files to have the
  # same identifier. It is therefore recommended to avoid such situations.
  #
  # Some more examples:
  #
  #   content/index.html          --> /
  #   content/foo.html            --> /foo/
  #   content/foo/index.html      --> /foo/
  #   content/foo/bar.html        --> /foo/bar/
  #   content/foo/bar/index.html  --> /foo/bar/
  #
  # File extensions are ignored by nanoc. The file extension does not
  # determine the filters to run on it; the metadata in the file defines the
  # list of filters.
  #
  # = Assets
  #
  # Assets are stored in a way similar to pages. The attributes are merged
  # into the asset.
  #
  # = Layouts
  #
  # Layouts are stored as files in the 'layouts' directory. Similar to pages,
  # each layout consists of a metadata part and a content part, separated by
  # '-----'.
  #
  # = Code
  #
  # Code is stored in '.rb' files in the 'lib' directory. Code can reside in
  # sub-directories.
  class FilesystemCombined < Nanoc::DataSource

    ########## Attributes ##########

    identifier :filesystem_combined

    ########## VCSes ##########

    attr_accessor :vcs

    def vcs
      @vcs ||= Nanoc::Extra::VCSes::Dummy.new
    end

    ########## Preparation ##########

    def up # :nodoc:
    end

    def down # :nodoc:
    end

    def setup # :nodoc:
      # Create directories
      %w( assets content layouts lib ).each do |dir|
        FileUtils.mkdir_p(dir)
        vcs.add(dir)
      end
    end

    def destroy # :nodoc:
      # Remove directories
      vcs.remove('assets')
      vcs.remove('content')
      vcs.remove('layouts')
      vcs.remove('lib')
    end

    ########## Pages ##########

    def pages # :nodoc:
      files('content', true).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, 'page')

        # Get attributes
        attributes = meta.merge(:file => Nanoc::Extra::FileProxy.new(filename))

        # Get actual identifier
        if filename =~ /\/index\.[^\/]+$/
          identifier = filename.sub(/^content/, '').sub(/index\.[^\/]+$/, '') + '/'
        else
          identifier = filename.sub(/^content/, '').sub(/\.[^\/]+$/, '') + '/'
        end

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build page
        Nanoc::Page.new(content, attributes, identifier, mtime)
      end
    end

    def save_page(page) # :nodoc:
      # Find page path
      if page.identifier == '/'
        paths         = Dir['content/index.*']
        path          = paths[0] || 'content/index.html'
        parent_path   = '/'
      else
        last_path_component = page.identifier.split('/')[-1]
        paths_best    = Dir['content' + page.identifier[0..-2] + '.*']
        paths_worst   = Dir['content' + page.identifier + 'index.*']
        path_default  = 'content' + page.identifier[0..-2] + '.html'
        path          = paths_best[0] || paths_worst[0] || path_default
        parent_path   = '/' + File.join(page.identifier.split('/')[0..-2])
      end

      # Notify
      if File.file?(path)
        created = false
        Nanoc::NotificationCenter.post(:file_updated, path)
      else
        created = true
        Nanoc::NotificationCenter.post(:file_created, path)
      end

      # Write page
      FileUtils.mkdir_p('content' + parent_path)
      File.open(path, 'w') do |io|
        io.write("-----\n")
        io.write(YAML.dump(page.attributes.stringify_keys) + "\n")
        io.write("-----\n")
        io.write(page.content)
      end

      # Add to working copy if possible
      vcs.add(path) if created
    end

    ########## Assets ##########

    def assets # :nodoc:
      files('assets', true).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, 'asset')

        # Get attributes
        attributes = { 'extension' => File.extname(filename)[1..-1] }.merge(meta)

        # Get actual identifier
        if filename =~ /\/index\.[^\/]+$/
          identifier = filename.sub(/^assets/, '').sub(/index\.[^\/]+$/, '') + '/'
        else
          identifier = filename.sub(/^assets/, '').sub(/\.[^\/]+$/, '') + '/'
        end

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build asset
        Nanoc::Asset.new(content, attributes, identifier, mtime)
      end
    end

    def save_asset(asset) # :nodoc:
      # TODO implement
    end

    ########## Layouts ##########

    def layouts # :nodoc:
      files('layouts', true).map do |filename|
        # Read and parse data
        meta, content = *parse_file(filename, 'layout')

        # Get actual identifier
        if filename =~ /\/index\.[^\/]+$/
          identifier = filename.sub(/^layouts/, '').sub(/index\.[^\/]+$/, '') + '/'
        else
          identifier = filename.sub(/^layouts/, '').sub(/\.[^\/]+$/, '') + '/'
        end

        # Get mtime
        mtime = File.stat(filename).mtime

        # Build layout
        Nanoc::Layout.new(content, meta, identifier, mtime)
      end.compact
    end

    def save_layout(layout) # :nodoc:
      # Find layout path
      last_path_component = layout.identifier.split('/')[-1]
      paths_best    = Dir['layouts' + layout.identifier[0..-2] + '.*']
      paths_worst   = Dir['layouts' + layout.identifier + 'index.*']
      path_default  = 'layouts' + layout.identifier[0..-2] + '.html'
      path          = paths_best[0] || paths_worst[0] || path_default
      parent_path   = '/' + File.join(layout.identifier.split('/')[0..-2])

      # Notify
      if File.file?(path)
        created = false
        Nanoc::NotificationCenter.post(:file_updated, path)
      else
        created = true
        Nanoc::NotificationCenter.post(:file_created, path)
      end

      # Write layout
      FileUtils.mkdir_p('layouts' + parent_path)
      File.open(path, 'w') do |io|
        io.write("-----\n")
        io.write(YAML.dump(layout.attributes.stringify_keys) + "\n")
        io.write("-----\n")
        io.write(layout.content)
      end

      # Add to working copy if possible
      vcs.add(path) if created
    end

    ########## Code ##########

    def code # :nodoc:
      # Get files
      filenames = Dir['lib/**/*.rb'].sort

      # Read snippets
      snippets = filenames.map do |fn|
        { :filename => fn, :code => File.read(fn) }
      end

      # Get modification time
      mtimes = filenames.map { |filename| File.stat(filename).mtime }
      mtime = mtimes.inject { |memo, mtime| memo > mtime ? mtime : memo }

      # Build code
      Nanoc::Code.new(snippets, mtime)
    end

    # FIXME update
    def save_code(code) # :nodoc:
      # Check whether code existed
      existed = File.file?('lib/default.rb')

      # Remove all existing code files
      Dir['lib/**/*.rb'].each do |file|
        vcs.remove(file) unless file == 'lib/default.rb'
      end

      # Notify
      if existed
        Nanoc::NotificationCenter.post(:file_updated, 'lib/default.rb')
      else
        Nanoc::NotificationCenter.post(:file_created, 'lib/default.rb')
      end

      # Write new code
      File.open('lib/default.rb', 'w') do |io|
        io.write(code.data)
      end

      # Add to working copy if possible
      vcs.add('lib/default.rb') unless existed
    end

  private

    # Returns a list of all files in +dir+, ignoring any unwanted files (files
    # that end with '~', '.orig', '.rej' or '.bak').
    #
    # +recursively+:: When +true+, finds files in +dir+ as well as its
    #                 subdirectories; when +false+, only searches +dir+
    #                 itself.
    def files(dir, recursively)
      glob = File.join([dir] + (recursively ? [ '**', '*' ] : [ '*' ]))
      Dir[glob].reject { |f| File.directory?(f) or f =~ /(~|\.orig|\.rej|\.bak)$/ }
    end

    # Parses the file named +filename+ and returns an array with its first
    # element a hash with the file's metadata, and with its second element the
    # file content itself.
    def parse_file(filename, kind)
      # Split file
      pieces = File.read(filename).split(/^-----/)
      if pieces.size < 3
        raise RuntimeError.new(
          "The file '#{filename}' does not seem to be a nanoc #{kind}"
        )
      end

      # Parse
      meta    = YAML.load(pieces[1]) || {}
      content = pieces[2..-1].join.strip

      [ meta, content ]
    end

  end

end
