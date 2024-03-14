# frozen_string_literal: true

usage 'create-site [options] path'
aliases :create_site, :cs
summary 'create a site'
description 'Create a new site at the given path. The site will use the `filesystem` data source.'
flag nil, :force, 'force creation of new site'
param :path

module Nanoc::CLI::Commands
  class CreateSite < ::Nanoc::CLI::CommandRunner
    class << self
      protected

      # Converts the given array to YAML format
      def array_to_yaml(array)
        '[ ' + array.map { |s| "'" + s + "'" }.join(', ') + ' ]'
      end
    end

    DEFAULT_GEMFILE = <<~EOS unless defined? DEFAULT_GEMFILE
      # frozen_string_literal: true

      source 'https://rubygems.org'

      gem 'nanoc', '~> #{Nanoc::CLI::VERSION.split('.').take(2).join('.')}'
    EOS

    DEFAULT_CONFIG = <<~EOS unless defined? DEFAULT_CONFIG
      # A list of file extensions that Nanoc will consider to be textual rather than
      # binary. If an item with an extension not in this list is found,  the file
      # will be considered as binary.
      text_extensions: #{array_to_yaml(Nanoc::Core::Configuration::DEFAULT_CONFIG[:text_extensions])}

      prune:
        auto_prune: true

      data_sources:
        - type: filesystem
          encoding: utf-8
    EOS

    DEFAULT_RULES = <<~EOS unless defined? DEFAULT_RULES
      #!/usr/bin/env ruby

      compile '/**/*.html' do
        layout '/default.*'

        if item.identifier =~ '**/index.*'
          write item.identifier.to_s
        else
          write item.identifier.without_ext + '/index.html'
        end
      end

      # This is an example rule that matches Markdown (.md) files, and filters them
      # using the :kramdown filter. It is commented out by default, because kramdown
      # is not bundled with Nanoc or Ruby.
      #
      #compile '/**/*.md' do
      #  filter :kramdown
      #  layout '/default.*'
      #
      #  if item.identifier =~ '**/index.*'
      #    write item.identifier.without_ext + '.html'
      #  else
      #    write item.identifier.without_ext + '/index.html'
      #  end
      #end

      passthrough '/**/*'

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
              <li><a href="https://nanoc.app/doc/">Documentation</a></li>
              <li><a href="https://nanoc.app/doc/tutorial/">Tutorial</a></li>
            </ul>
            <h2>Community</h2>
            <ul>
              <li><a href="http://groups.google.com/group/nanoc/">Discussion group</a></li>
              <li><a href="https://gitter.im/nanoc/nanoc">Gitter channel</a></li>
              <li><a href="https://nanoc.app/contributing/">Contributing</a></li>
            </ul>
          </div>
        </body>
      </html>
    EOS

    def run
      path = arguments[:path]

      # Check whether site exists
      if File.exist?(path) && (!File.directory?(path) || !(Dir.entries(path) - %w[. ..]).empty?) && !options[:force]
        raise(
          Nanoc::Core::TrivialError,
          "The site was not created because '#{path}' already exists. " \
          'Re-run the command using --force to create the site anyway.',
        )
      end

      # Build entire site
      FileUtils.mkdir_p(path)
      FileUtils.cd(File.join(path)) do
        FileUtils.mkdir_p('content')
        FileUtils.mkdir_p('layouts')
        FileUtils.mkdir_p('lib')
        FileUtils.mkdir_p('output')

        write('Gemfile', DEFAULT_GEMFILE)
        write('nanoc.yaml', DEFAULT_CONFIG)
        write('Rules', DEFAULT_RULES)
        write('content/index.html', DEFAULT_ITEM)
        write('content/stylesheet.css', DEFAULT_STYLESHEET)
        write('layouts/default.html', DEFAULT_LAYOUT)
      end

      puts "Created a blank Nanoc site at '#{path}'. Enjoy!"
    end

    private

    def write(filename, content)
      File.write(filename, content)
      Nanoc::CLI::Logger.instance.file(:high, :create, filename)
    end
  end
end

runner Nanoc::CLI::Commands::CreateSite
