# encoding: utf-8

usage       'create-item [options] identifier'
aliases     :create_item, :ci
summary     'create an item'
description <<-EOS
Create a new item in the current site. The first data source in the site
configuration will be used.
EOS

required :c, :vcs, 'specify the VCS to use'

module Nanoc::CLI::Commands

  class CreateItem < ::Nanoc::CLI::CommandRunner

    def run
      # Check arguments
      if arguments.length != 1
        raise Nanoc::Errors::GenericTrivial, "usage: #{command.usage}"
      end

      # Extract arguments and options
      identifier = arguments[0].cleaned_identifier

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
        "Hi, I'm a new item!\n",
        { :title => "A New Item" },
        identifier
      )

      puts "An item has been created at #{identifier}."
    end

  end

end

runner Nanoc::CLI::Commands::CreateItem
