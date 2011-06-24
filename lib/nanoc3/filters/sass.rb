# encoding: utf-8

require 'sass'

module Nanoc3::Filters
  class Sass < Nanoc3::Filter

    # Runs the content through [Sass](http://sass-lang.com/).
    # Parameters passed to this filter will be passed on to Sass.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Add imported_filename read accessor to ImportNode
      # … but… but… nex3 said I could monkey patch it! :(
      methods = ::Sass::Tree::ImportNode.instance_methods
      if !methods.include?(:import_filename) && !methods.include?('import_filename')
        ::Sass::Tree::ImportNode.send(:attr_reader, :imported_filename)
      end

      # Get options
      options = params.dup
      sass_filename = options[:filename] || (@item && @item[:content_filename])
      options[:filename] ||= sass_filename

      # Build engine
      engine = ::Sass::Engine.new(content, options)

      # Get import nodes
      imported_nodes = []
      unprocessed_nodes = Set.new([ engine.to_tree ])
      until unprocessed_nodes.empty?
        # Get an unprocessed node
        node = unprocessed_nodes.each { |n| break n }
        unprocessed_nodes.delete(node)

        # Add to list of import nodes if necessary
        imported_nodes << node if node.is_a?(::Sass::Tree::ImportNode)

        # Mark children of this node for processing
        node.children.each { |c| unprocessed_nodes << c }
      end

      # Get import paths
      import_paths = (options[:load_paths] || []).dup
      import_paths.unshift(File.dirname(sass_filename)) if sass_filename
      imported_filenames = imported_nodes.map { |node| node.imported_filename }

      # Convert to items
      imported_items = imported_filenames.map do |filename|
        # Find directory for this item
        current_dir_pathname = Pathname.new(@item[:content_filename]).dirname.realpath

        # Find absolute pathname for imported item
        imported_pathname    = Pathname.new(filename)
        if imported_pathname.relative?
          imported_pathname = current_dir_pathname + imported_pathname
        end
        next if !imported_pathname.exist?
        imported_filename = imported_pathname.realpath

        # Find matching item
        @items.find do |i|
          next if i[:content_filename].nil?
          Pathname.new(i[:content_filename]).realpath == imported_filename
        end
      end.compact

      # Require compilation of each item
      depend_on(imported_items)

      # Done
      engine.render
    end

  end
end
