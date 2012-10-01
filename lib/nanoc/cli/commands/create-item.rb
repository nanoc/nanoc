# encoding: utf-8

usage       'create-item [options] identifier|-i [title [content]]'
aliases     :create_item, :ci
summary     'create an item'
description <<-EOS
Create a new item in the current site. The first data source in the site
configuration will be used. Surround title and content with quotes if they
contain whitespace. If only identifier is provided, title defaults
to "A New Item", and content defaults to a cheery greeting.
EOS

required :c, :vcs, 'specify the VCS to use'
flag :i, :'make-id', 'generate identifier from title'
required :p, :'id-prefix', 'add this text to start of identifier'

module Nanoc::CLI::Commands

  class CreateItem < ::Nanoc::CLI::CommandRunner

    def run
      # Check arguments
      if arguments.length < 1
        raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      if arguments.length > (options[:'make-id'] ? 2 : 3)
        raise Nanoc::Errors::GenericTrivial, "too many arguments (surround " +
          "title and content with quotes), usage: #{command.usage}"
      end

      # Extract arguments and options
      prefix = options[:'id-prefix'] || ""
      if options[:'make-id']
        title = arguments[0]
        content = arguments[1] || ""
        identifier = (prefix + title).slug.cleaned_identifier
      else
        identifier = (prefix + arguments[0]).cleaned_identifier
        title = arguments[1] || "A New Item"
        content = arguments[2] || (arguments[1] ? "" : "Hi, I'm a new item!")
      end

      # Make sure we are in a nanoc site directory
      self.require_site

      # Set VCS if possible
      self.set_vcs(options[:vcs])

      # Check whether item is unique
      if !self.site.items.find { |i| i.identifier == identifier }.nil?
        raise Nanoc::Errors::GenericTrivial,
          "An item already exists at #{identifier}. Please " +
          "pick a unique name for the item you are creating."
      end

      # Setup notifications
      Nanoc::NotificationCenter.on(:file_created) do |file_path|
        Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
      end

      # Create item
      data_source = self.site.data_sources[0]
      data_source.create_item(
        content + "\n",
        { :title => title },
        identifier
      )

      puts "An item has been created at #{identifier}."
    end

  end

end

runner Nanoc::CLI::Commands::CreateItem
