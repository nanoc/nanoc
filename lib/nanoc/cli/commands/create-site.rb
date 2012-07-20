# encoding: utf-8

usage       'create-site [options] path'
aliases     :create_site, :cs
summary     'create a site'
description <<-EOS
Create a new site at the given path. The site will use the filesystem_unified data source by default, but this can be changed using the --datasource commandline option.
EOS

required :d, :datasource, 'specify the data source for the new site'

module Nanoc::CLI::Commands

  class CreateSite < ::Nanoc::CLI::CommandRunner

    class << self

    protected

      # Converts the given array to YAML format
      def array_to_yaml(array)
        '[ ' + array.map { |s| "'" + s + "'" }.join(', ') + ' ]'
      end

    end

    DEFAULT_CONFIG = <<EOS
# A list of file extensions that nanoc will consider to be textual rather than
# binary. If an item with an extension not in this list is found,  the file
# will be considered as binary.
text_extensions: #{array_to_yaml(Nanoc::Site::DEFAULT_CONFIG[:text_extensions])}

# The path to the directory where all generated files will be written to. This
# can be an absolute path starting with a slash, but it can also be path
# relative to the site directory.
output_dir: #{Nanoc::Site::DEFAULT_CONFIG[:output_dir]}

# A list of index filenames, i.e. names of files that will be served by a web
# server when a directory is requested. Usually, index files are named
# “index.html”, but depending on the web server, this may be something else,
# such as “default.htm”. This list is used by nanoc to generate pretty URLs.
index_filenames: #{array_to_yaml(Nanoc::Site::DEFAULT_CONFIG[:index_filenames])}

# Whether or not to generate a diff of the compiled content when compiling a
# site. The diff will contain the differences between the compiled content
# before and after the last site compilation.
enable_output_diff: false

prune:
  # Whether to automatically remove files not managed by nanoc from the output
  # directory. For safety reasons, this is turned off by default.
  auto_prune: false

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
    type: #{Nanoc::Site::DEFAULT_DATA_SOURCE_CONFIG[:type]}

    # The path where items should be mounted (comparable to mount points in
    # Unix-like systems). This is “/” by default, meaning that items will have
    # “/” prefixed to their identifiers. If the items root were “/en/”
    # instead, an item at content/about.html would have an identifier of
    # “/en/about/” instead of just “/about/”.
    items_root: #{Nanoc::Site::DEFAULT_DATA_SOURCE_CONFIG[:items_root]}

    # The path where layouts should be mounted. The layouts root behaves the
    # same as the items root, but applies to layouts rather than items.
    layouts_root: #{Nanoc::Site::DEFAULT_DATA_SOURCE_CONFIG[:layouts_root]}

    # Whether to allow periods in identifiers. When turned off, everything
    # past the first period is considered to be the extension, and when
    # turned on, only the characters past the last period are considered to
    # be the extension. For example,  a file named “content/about.html.erb”
    # will have the identifier “/about/” when turned off, but when turned on
    # it will become “/about.html/” instead.
    allow_periods_in_identifiers: false

# Configuration for the “watch” command, which watches a site for changes and
# recompiles if necessary.
watcher:
  # A list of directories to watch for changes. When editing this, make sure
  # that the “output/” and “tmp/” directories are _not_ included in this list,
  # because recompiling the site will cause these directories to change, which
  # will cause the site to be recompiled, which will cause these directories
  # to change, which will cause the site to be recompiled again, and so on.
  dirs_to_watch: [ 'content', 'layouts', 'lib' ]

  # A list of single files to watch for changes. As mentioned above, don’t put
  # any files from the “output/” or “tmp/” directories in here.
  files_to_watch: [ 'config.yaml', 'Rules' ]

  # When to send notifications (using Growl or notify-send).
  notify_on_compilation_success: true
  notify_on_compilation_failure: true
EOS

    DEFAULT_RULES = <<EOS
#!/usr/bin/env ruby

# A few helpful tips about the Rules file:
#
# * The string given to #compile and #route are matching patterns for
#   identifiers--not for paths. Therefore, you can’t match on extension.
#
# * The order of rules is important: for each item, only the first matching
#   rule is applied.
#
# * Item identifiers start and end with a slash (e.g. “/about/” for the file
#   “content/about.html”). To select all children, grandchildren, … of an
#   item, use the pattern “/about/*/”; “/about/*” will also select the parent,
#   because “*” matches zero or more characters.

compile '/stylesheet/' do
  # don’t filter or layout
end

compile '*' do
  if item.binary?
    # don’t filter binary items
  else
    filter :erb
    layout 'default'
  end
end

route '/stylesheet/' do
  '/style.css'
end

route '*' do
  if item.binary?
    # Write item with identifier /foo/ to /foo.ext
    item.identifier.chop + '.' + item[:extension]
  else
    # Write item with identifier /foo/ to /foo/index.html
    item.identifier + 'index.html'
  end
end

layout '*', :erb
EOS

    DEFAULT_ITEM = <<EOS
<h1>A Brand New nanoc Site</h1>

<p>You’ve just created a new nanoc site. The page you are looking at right now is the home page for your site. To get started, consider replacing this default homepage with your own customized homepage. Some pointers on how to do so:</p>

<ul>
  <li><p><strong>Change this page’s content</strong> by editing the “index.html” file in the “content” directory. This is the actual page content, and therefore doesn’t include the header, sidebar or style information (those are part of the layout).</p></li>
  <li><p><strong>Change the layout</strong>, which is the “default.html” file in the “layouts” directory, and create something unique (and hopefully less bland).</p></li>
</ul>

<p>If you need any help with customizing your nanoc web site, be sure to check out the documentation (see sidebar), and be sure to subscribe to the discussion group (also see sidebar). Enjoy!</p>
EOS

    DEFAULT_STYLESHEET = <<EOS
* {
  margin: 0;
  padding: 0;

  font-family: Georgia, Palatino, Times, 'Times New Roman', sans-serif;
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

    DEFAULT_LAYOUT = <<EOS
<!DOCTYPE HTML>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>A Brand New nanoc Site - <%= @item[:title] %></title>
    <link rel="stylesheet" href="/style.css">

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
        <li><a href="http://nanoc.stoneship.org/docs/">Documentation</a></li>
        <li><a href="http://nanoc.stoneship.org/docs/3-getting-started/">Getting Started</a></li>
      </ul>
      <h2>Community</h2>
      <ul>
        <li><a href="http://groups.google.com/group/nanoc/">Discussion Group</a></li>
        <li><a href="irc://chat.freenode.net/#nanoc">IRC Channel</a></li>
        <li><a href="http://projects.stoneship.org/trac/nanoc/">Wiki</a></li>
      </ul>
    </div>
  </body>
</html>
EOS

    def run
      # Check arguments
      if arguments.length != 1
        raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      # Extract arguments and options
      path        = arguments[0]
      data_source = options[:datasource] || 'filesystem_unified'

      # Check whether site exists
      if File.exist?(path)
        raise Nanoc::Errors::GenericTrivial, "A site at '#{path}' already exists."
      end

      # Check whether data source exists
      if Nanoc::DataSource.named(data_source).nil?
        raise Nanoc::Errors::GenericTrivial, "Unrecognised data source: #{data_source}"
      end

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Build entire site
      FileUtils.mkdir_p(path)
      FileUtils.cd(File.join(path)) do
        site_create_minimal(data_source)
        site_setup
        site_populate
      end

      puts "Created a blank nanoc site at '#{path}'. Enjoy!"
    end

  protected

    # Creates a configuration file and a output directory for this site, as
    # well as a rakefile that loads the standard nanoc tasks.
    def site_create_minimal(data_source)
      # Create output
      FileUtils.mkdir_p('output')

      # Create config
      File.open('config.yaml', 'w') { |io| io.write(DEFAULT_CONFIG) }
      Nanoc::NotificationCenter.post(:file_created, 'config.yaml')

      # Create rules
      File.open('Rules', 'w') do |io|
        io.write DEFAULT_RULES
      end
      Nanoc::NotificationCenter.post(:file_created, 'Rules')
    end

    # Sets up the site's data source, i.e. creates the bare essentials for
    # this data source to work.
    def site_setup
      # Get site
      site = Nanoc::Site.new('.')

      # Set up data sources
      site.data_sources.each do |data_source|
        data_source.loading { data_source.setup }
      end
    end

    # Populates the site with some initial data, such as a root item, a
    # default layout, and so on.
    def site_populate
      # Get site
      site = Nanoc::Site.new('.')
      data_source = site.data_sources[0]

      # Create home page
      data_source.create_item(
        DEFAULT_ITEM,
        { :title => "Home" },
        '/'
      )

      # Create stylesheet
      data_source.create_item(
        DEFAULT_STYLESHEET,
        {},
        '/stylesheet/',
        :extension => '.css'
      )

      # Create layout
      data_source.create_layout(
        DEFAULT_LAYOUT,
        {},
        '/default/'
      )

      # Create code
      FileUtils.mkdir_p('lib')
      File.open('lib/default.rb', 'w') do |io|
        io.write "\# All files in the 'lib' directory will be loaded\n"
        io.write "\# before nanoc starts compiling.\n"
      end
    end

  end

end

runner Nanoc::CLI::Commands::CreateSite
