# frozen_string_literal: true

usage 'create-site [options] path'
aliases :create_site, :cs
summary 'create a site'
description 'Create a new site at the given path. The site will use the `filesystem` data source.'
flag nil, :force, 'force creation of new site'

module Nanoc::CLI::Commands
  class CreateSite < ::Nanoc::CLI::CommandRunner
    class << self
      protected

      # Converts the given array to YAML format
      def array_to_yaml(array)
        '[ ' + array.map { |s| "'" + s + "'" }.join(', ') + ' ]'
      end
    end

    DEFAULT_CONFIG = <<~EOS unless defined? DEFAULT_CONFIG
      # The syntax to use for patterns in the Rules file. Can be either `"glob"`
      # (default) or `"legacy"`. The former will enable glob patterns, which behave
      # like Ruby’s File.fnmatch. The latter will enable Nanoc 3.x-style patterns.
      string_pattern_type: glob

      # A list of file extensions that Nanoc will consider to be textual rather than
      # binary. If an item with an extension not in this list is found,  the file
      # will be considered as binary.
      text_extensions: #{array_to_yaml(Nanoc::Int::Configuration::DEFAULT_CONFIG[:text_extensions])}

      # The path to the directory where all generated files will be written to. This
      # can be an absolute path starting with a slash, but it can also be path
      # relative to the site directory.
      output_dir: #{Nanoc::Int::Configuration::DEFAULT_CONFIG[:output_dir]}

      # A list of index filenames, i.e. names of files that will be served by a web
      # server when a directory is requested. Usually, index files are named
      # “index.html”, but depending on the web server, this may be something else,
      # such as “default.htm”. This list is used by Nanoc to generate pretty URLs.
      index_filenames: #{array_to_yaml(Nanoc::Int::Configuration::DEFAULT_CONFIG[:index_filenames])}

      # Whether or not to generate a diff of the compiled content when compiling a
      # site. The diff will contain the differences between the compiled content
      # before and after the last site compilation.
      enable_output_diff: false

      prune:
        # Whether to automatically remove files not managed by Nanoc from the output
        # directory.
        auto_prune: true

        # Which files and directories you want to exclude from pruning. If you version
        # your output directory, you should probably exclude VCS directories such as
        # .git, .svn etc.
        exclude: [ '.git', '.hg', '.svn', 'CVS' ]

      # The data sources where Nanoc loads its data from. This is an array of
      # hashes; each array element represents a single data source. By default,
      # there is only a single data source that reads data from the “content/” and
      # “layout/” directories in the site directory.
      data_sources:
        -
          # The type is the identifier of the data source.
          type: #{Nanoc::Int::Configuration::DEFAULT_DATA_SOURCE_CONFIG[:type]}

          # The path where items should be mounted (comparable to mount points in
          # Unix-like systems). This is “/” by default, meaning that items will have
          # “/” prefixed to their identifiers. If the items root were “/en/”
          # instead, an item at content/about.html would have an identifier of
          # “/en/about/” instead of just “/about/”.
          items_root: #{Nanoc::Int::Configuration::DEFAULT_DATA_SOURCE_CONFIG[:items_root]}

          # The path where layouts should be mounted. The layouts root behaves the
          # same as the items root, but applies to layouts rather than items.
          layouts_root: #{Nanoc::Int::Configuration::DEFAULT_DATA_SOURCE_CONFIG[:layouts_root]}

          # The encoding to use for input files. If your input files are not in
          # UTF-8 (which they should be!), change this.
          encoding: utf-8

          # The kind of identifier to use for items and layouts. The default is
          # “full”, meaning that identifiers include file extensions. This can also
          # be “legacy”, primarily used by older Nanoc sites.
          identifier_type: full

      # Configuration for the “check” command, which run unit tests on the site.
      checks:
        # Configuration for the “internal_links” checker, which checks whether all
        # internal links are valid.
        internal_links:
          # A list of patterns, specified as regular expressions, to exclude from the check.
          # If an internal link matches this pattern, the validity check will be skipped.
          # E.g.:
          #   exclude: ['^/server_status']
          exclude: []

        # Configuration for the “external_links” checker, which checks whether all
        # external links are valid.
        external_links:
          # A list of patterns, specified as regular expressions, to exclude from the check.
          # If an external link matches this pattern, the validity check will be skipped.
          # E.g.:
          #   exclude: ['^http://example.com$']
          exclude: []

          # A list of file patterns, specified as regular expressions, to exclude from the check.
          # If a file matches this pattern, the links from this file will not be checked.
          # E.g.:
          #   exclude_files: ['blog/page']
          exclude_files: []
EOS

    DEFAULT_RULES = <<~EOS unless defined? DEFAULT_RULES
      #!/usr/bin/env ruby

      compile '/**/*.html' do
        layout '/default.*'
      end

      # This is an example rule that matches Markdown (.md) files, and filters them
      # using the :kramdown filter. It is commented out by default, because kramdown
      # is not bundled with Nanoc or Ruby.
      #
      #compile '/**/*.md' do
      #  filter :kramdown
      #  layout '/default.*'
      #end

      route '/**/*.{html,md}' do
        if item.identifier =~ '/index.*'
          '/index.html'
        else
          item.identifier.without_ext + '/index.html'
        end
      end

      compile '/**/*' do
        write item.identifier.to_s
      end

      layout '/**/*', :erb
EOS

    DEFAULT_ITEM = <<~EOS unless defined? DEFAULT_ITEM
      ---
      title: Home
      ---

      <h1>A Brand New Nanoc Site</h1>

      <p>You’ve just created a new Nanoc site. The page you are looking at right now is the home page for your site. To get started, consider replacing this default homepage with your own customized homepage. Some pointers on how to do so:</p>

      <ul>
        <li><p><strong>Change this page’s content</strong> by editing the “index.html” file in the “content” directory. This is the actual page content, and therefore doesn’t include the header, sidebar or style information (those are part of the layout).</p></li>
        <li><p><strong>Change the layout</strong>, which is the “default.html” file in the “layouts” directory, and create something unique (and hopefully less bland).</p></li>
      </ul>

      <p>If you need any help with customizing your Nanoc web site, be sure to check out the documentation (see sidebar), and be sure to subscribe to the discussion group (also see sidebar). Enjoy!</p>
EOS

    DEFAULT_STYLESHEET = <<~EOS unless defined? DEFAULT_STYLESHEET
      * {
        margin: 0;
        padding: 0;

        font-family: Georgia, Palatino, serif;
      }

      body {
        background: #fff;
      }

      a {
        text-decoration: none;
      }

      a:link,
      a:visited {
        color: #f30;
      }

      a:hover {
        color: #f90;
      }

      #main {
        position: absolute;

        top: 40px;
        left: 280px;

        width: 500px;
      }

      #main h1 {
        font-size: 40px;
        font-weight: normal;

        line-height: 40px;

        letter-spacing: -1px;
      }

      #main p {
        margin: 20px 0;

        font-size: 15px;

        line-height: 20px;
      }

      #main ul, #main ol {
        margin: 20px;
      }

      #main li {
        font-size: 15px;

        line-height: 20px;
      }

      #main ul li {
        list-style-type: square;
      }

      #sidebar {
        position: absolute;

        top: 40px;
        left: 20px;
        width: 200px;

        padding: 20px 20px 0 0;

        border-right: 1px solid #ccc;

        text-align: right;
      }

      #sidebar h2 {
        text-transform: uppercase;

        font-size: 13px;

        color: #333;

        letter-spacing: 1px;

        line-height: 20px;
      }

      #sidebar ul {
        list-style-type: none;

        margin: 20px 0;
      }

      #sidebar li {
        font-size: 14px;

        line-height: 20px;
      }
EOS

    DEFAULT_LAYOUT = <<~EOS unless defined? DEFAULT_LAYOUT
      <!DOCTYPE HTML>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>A Brand New Nanoc Site - <%= @item[:title] %></title>
          <link rel="stylesheet" href="/stylesheet.css">

          <!-- you don't need to keep this, but it's cool for stats! -->
          <meta name="generator" content="Nanoc <%= Nanoc::VERSION %>">
        </head>
        <body>
          <div id="main">
            <%= yield %>
          </div>
          <div id="sidebar">
            <h2>Documentation</h2>
            <ul>
              <li><a href="http://nanoc.ws/doc/">Documentation</a></li>
              <li><a href="http://nanoc.ws/doc/tutorial/">Tutorial</a></li>
            </ul>
            <h2>Community</h2>
            <ul>
              <li><a href="http://groups.google.com/group/nanoc/">Discussion group</a></li>
              <li><a href="https://gitter.im/nanoc/nanoc">Gitter channel</a></li>
              <li><a href="http://nanoc.ws/contributing/">Contributing</a></li>
            </ul>
          </div>
        </body>
      </html>
EOS

    def run
      # Extract arguments
      if arguments.length != 1
        raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
      end
      path = arguments[0]

      # Check whether site exists
      if File.exist?(path) && (!File.directory?(path) || !(Dir.entries(path) - %w[. ..]).empty?) && !options[:force]
        raise(
          Nanoc::Int::Errors::GenericTrivial,
          "The site was not created because '#{path}' already exists. " \
          'Re-run the command using --force to create the site anyway.',
        )
      end

      # Setup notifications
      Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Build entire site
      FileUtils.mkdir_p(path)
      FileUtils.cd(File.join(path)) do
        FileUtils.mkdir_p('content')
        FileUtils.mkdir_p('layouts')
        FileUtils.mkdir_p('lib')
        FileUtils.mkdir_p('output')

        write('nanoc.yaml', DEFAULT_CONFIG)
        write('Rules', DEFAULT_RULES)
        write('content/index.html', DEFAULT_ITEM)
        write('content/stylesheet.css', DEFAULT_STYLESHEET)
        write('layouts/default.html', DEFAULT_LAYOUT)
      end

      puts "Created a blank nanoc site at '#{path}'. Enjoy!"
    end

    private

    def write(filename, content)
      File.write(filename, content)
      Nanoc::Int::NotificationCenter.post(:file_created, filename)
    end
  end
end

runner Nanoc::CLI::Commands::CreateSite
