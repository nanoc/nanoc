# encoding: utf-8

usage       'create-layout [options] identifier'
aliases     :create_layout, :cl
summary     'create a layout'
description <<-EOS
Create a new layout in the current site. The first data source in the site
configuration will be used.
EOS

module Nanoc::CLI::Commands

  class CreateLayout < ::Nanoc::CLI::CommandRunner

    def run
      # Check arguments
      if arguments.length != 1
        raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      # Extract arguments
      identifier = arguments[0].cleaned_identifier

      # Make sure we are in a nanoc site directory
      self.require_site

      # Set VCS if possible
      self.set_vcs(options[:vcs])

      # Check whether layout is unique
      if !self.site.layouts.find { |l| l.identifier == identifier }.nil?
        raise Nanoc::Errors::GenericTrivial,
          "A layout already exists at #{identifier}. Please " +
          "pick a unique name for the layout you are creating."
      end

      # Check whether layout is not at /
      if identifier == '/'
        raise Nanoc::Errors::GenericTrivial,
          "There cannot be a layout with the identifier '/'; " +
          "please pick a different identifier for this layout."
      end

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create layout
      data_source = self.site.data_sources[0]
      data_source.create_layout(
        "<html>\n" +
        "  <head>\n" +
        "    <title><%= @item[:title] %></title>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "    <p>Hi, I'm a new layout. Please customize me!</p>\n" +
        "<%= yield %>\n" +
        "  </body>\n" +
        "</html>\n",
        {},
        identifier
      )

      puts "A layout has been created at #{identifier}."
    end

  end

end

runner Nanoc::CLI::Commands::CreateLayout
