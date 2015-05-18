# encoding: utf-8

usage 'create-site [options] path'
aliases :create_site, :cs
summary 'create a site'
description "
Create a new site at the given path. The site will use the `filesystem_unified` data source by default, but this can be changed using the `--datasource` command-line option.
"
flag nil, :force, "Force creation of new site. Disregards previous existence of site in destination"

module Nanoc::CLI::Commands
  class CreateSite < ::Nanoc::CLI::CommandRunner
    class << self
      protected

      # Converts the given array to YAML format
      def array_to_yaml(array)
        '[ ' + array.map { |s| "'" + s + "'" }.join(', ') + ' ]'
      end
    end

    DEFAULT_CONFIG = <<EOS unless defined? DEFAULT_CONFIG
# The syntax to use for patterns in the Rules file. Can be either `"glob"`
# (default) or `null`. The former will enable glob patterns, which behave like
# Ruby’s File.fnmatch. The latter will enable nanoc 3.x-style patterns.
string_pattern_type: glob

# A list of file extensions that nanoc will consider to be textual rather than
# binary. If an item with an extension not in this list is found,  the file
# will be considered as binary.
text_extensions: #{array_to_yaml(Nanoc::Int::Site::DEFAULT_CONFIG[:text_extensions])}

# The path to the directory where all generated files will be written to. This
# can be an absolute path starting with a slash, but it can also be path
# relative to the site directory.
output_dir: #{Nanoc::Int::Site::DEFAULT_CONFIG[:output_dir]}

# A list of index filenames, i.e. names of files that will be served by a web
# server when a directory is requested. Usually, index files are named
# “index.html”, but depending on the web server, this may be something else,
# such as “default.htm”. This list is used by nanoc to generate pretty URLs.
index_filenames: #{array_to_yaml(Nanoc::Int::Site::DEFAULT_CONFIG[:index_filenames])}

# Whether or not to generate a diff of the compiled content when compiling a
# site. The diff will contain the differences between the compiled content
# before and after the last site compilation.
enable_output_diff: false

prune:
  # Whether to automatically remove files not managed by nanoc from the output
  # directory.
  auto_prune: true

  # Which files and directories you want to exclude from pruning. If you version
  # your output directory, you should probably exclude VCS directories such as
  # .git, .svn etc.
  exclude: [ '.git', '.hg', '.svn', 'CVS' ]

# The data sources where nanoc loads its data from. This is an array of
# hashes; each array element represents a single data source. By default,
# there is only a single data source that reads data from the “content/” and
# “layout/” directories in the site directory.
data_sources:
  -
    # The type is the identifier of the data source. By default, this will be
    # `filesystem_unified`.
    type: #{Nanoc::Int::Site::DEFAULT_DATA_SOURCE_CONFIG[:type]}

    # The path where items should be mounted (comparable to mount points in
    # Unix-like systems). This is “/” by default, meaning that items will have
    # “/” prefixed to their identifiers. If the items root were “/en/”
    # instead, an item at content/about.html would have an identifier of
    # “/en/about/” instead of just “/about/”.
    items_root: #{Nanoc::Int::Site::DEFAULT_DATA_SOURCE_CONFIG[:items_root]}

    # The path where layouts should be mounted. The layouts root behaves the
    # same as the items root, but applies to layouts rather than items.
    layouts_root: #{Nanoc::Int::Site::DEFAULT_DATA_SOURCE_CONFIG[:layouts_root]}

    # Whether to allow periods in identifiers. When turned off, everything
    # past the first period is considered to be the extension, and when
    # turned on, only the characters past the last period are considered to
    # be the extension. For example,  a file named “content/about.html.erb”
    # will have the identifier “/about/” when turned off, but when turned on
    # it will become “/about.html/” instead.
    allow_periods_in_identifiers: false

    # The encoding to use for input files. If your input files are not in
    # UTF-8 (which they should be!), change this.
    encoding: utf-8

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
EOS

    DEFAULT_RULES = <<EOS unless defined? DEFAULT_RULES
#!/usr/bin/env ruby

compile '/**/*.html' do
  filter :erb
  layout '/default.*'
end

compile '/**/*' do
end

route '/**/*' do
  item.identifier.to_s
end

layout '/**/*', :erb
EOS

    DEFAULT_ITEM = <<EOS unless defined? DEFAULT_ITEM
<h1>A Brand New nanoc Site</h1>

<p>You’ve just created a new nanoc site. The page you are looking at right now is the home page for your site. To get started, consider replacing this default homepage with your own customized homepage. Some pointers on how to do so:</p>

<ul>
  <li><p><strong>Change this page’s content</strong> by editing the “index.html” file in the “content” directory. This is the actual page content, and therefore doesn’t include the header, sidebar or style information (those are part of the layout).</p></li>
  <li><p><strong>Change the layout</strong>, which is the “default.html” file in the “layouts” directory, and create something unique (and hopefully less bland).</p></li>
</ul>

<p>If you need any help with customizing your nanoc web site, be sure to check out the documentation (see sidebar), and be sure to subscribe to the discussion group (also see sidebar). Enjoy!</p>
EOS

    DEFAULT_STYLESHEET = <<EOS unless defined? DEFAULT_STYLESHEET
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

    DEFAULT_LAYOUT = <<EOS unless defined? DEFAULT_LAYOUT
<!DOCTYPE HTML>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>A Brand New nanoc Site - <%= @item[:title] %></title>
    <link rel="stylesheet" href="<%= @items['/stylesheet.*'].path %>">

    <!-- you don't need to keep this, but it's cool for stats! -->
    <meta name="generator" content="nanoc <%= Nanoc::VERSION %>">
  </head>
  <body>
    <div id="main">
      <%= yield %>
    </div>
    <div id="sidebar">
      <h2>Documentation</h2>
      <ul>
        <li><a href="http://nanoc.ws/docs/">Documentation</a></li>
        <li><a href="http://nanoc.ws/docs/tutorial/">Getting Started</a></li>
      </ul>
      <h2>Community</h2>
      <ul>
        <li><a href="http://groups.google.com/group/nanoc/">Discussion Group</a></li>
        <li><a href="irc://chat.freenode.net/#nanoc">IRC Channel</a></li>
        <li><a href="http://github.com/nanoc/nanoc/wiki/">Wiki</a></li>
      </ul>
    </div>
  </body>
</html>
EOS

    def run
      # Check arguments
      if arguments.length != 1
        raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      # Extract arguments and options
      path        = arguments[0]
      data_source = options[:datasource] || 'filesystem_unified'

      # Check whether site exists
      if File.exist?(path) && (!File.directory?(path) || !(Dir.entries(path) - %w{ . .. }).empty?) && !options[:force]
        raise Nanoc::Int::Errors::GenericTrivial,
          "The site was not created because '#{path}' already exists. " +
          "Re-run the command using --force to create the site anyway."
      end

      # Check whether data source exists
      if Nanoc::DataSource.named(data_source).nil?
        raise Nanoc::Int::Errors::GenericTrivial, "Unrecognised data source: #{data_source}"
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

        # Config
        File.open('nanoc.yaml', 'w') { |io| io.write(DEFAULT_CONFIG) }
        Nanoc::Int::NotificationCenter.post(:file_created, 'nanoc.yaml')

        # Rules
        File.open('Rules', 'w') do |io|
          io.write DEFAULT_RULES
        end
        Nanoc::Int::NotificationCenter.post(:file_created, 'Rules')

        # Home page
        File.open('content/index.html', 'w') do |io|
          io << '---' << "\n"
          io << 'title: Home' << "\n"
          io << '---' << "\n"
          io << "\n"
          io << DEFAULT_ITEM
        end
        Nanoc::Int::NotificationCenter.post(:file_created, 'content/index.html')

        # Style sheet
        File.open('content/stylesheet.css', 'w') do |io|
          io << DEFAULT_STYLESHEET
        end
        Nanoc::Int::NotificationCenter.post(:file_created, 'content/stylesheet.css')

        # Layout
        File.open('layouts/default.html', 'w') do |io|
          io << DEFAULT_LAYOUT
        end
        Nanoc::Int::NotificationCenter.post(:file_created, 'layouts/default.html')
      end

      puts "Created a blank nanoc site at '#{path}'. Enjoy!"
    end
  end
end

runner Nanoc::CLI::Commands::CreateSite
