# encoding: utf-8

module Nanoc::Filters
  class Less < Nanoc::Filter

    identifier :less

    requires 'less'

    def imports_in_content(content)
      # Find imports
      imports = []
      imports.concat(content.scan(/^@import\s+(["'])([^\1]+?)\1;/))
      imports.concat(content.scan(/^@import\s+url\((["']?)([^)]+?)\1\);/))

      # Append .less to flienames without extension
      imports.map do |i|
        i[1].match(/\.(less|css)$/) ? i[1] : i[1] + '.less'
      end
    end

    # Runs the content through [LESS](http://lesscss.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      # Find imports (hacky)
      imported_filenames = self.imports_in_content(content)

      # FIXME ugly
      paths = [ Dir.getwd + '/content' ]

      unless imported_filenames.empty?
        if @item.content.filename.nil?
          # FIXME get proper exception
          raise 'Can only use less filter with items that appear on disk (less limitation)'
        end
        current_item_filename = @item.content.filename
        current_dir_filename = File.dirname(current_item_filename)

        paths << current_dir_filename

        # Find items for imported filenames
        imported_items = imported_filenames.map do |imported_filename|
          # Find absolute filename for imported item
          imported_filename_absolute = File.join(current_dir_filename, imported_filename)

          # Find matching item
          @items.find { |i| i.content.filename == imported_filename_absolute }
        end.compact

        # Create dependencies
        depend_on(imported_items)
      end

      # Add filename to load path
      parser = ::Less::Parser.new(:paths => paths)
      parser.parse(content).to_css params
    end

  end
end
