module Nanoc::Filters
  # @api private
  class Less < Nanoc::Filter
    requires 'less'

    # Runs the content through [LESS](http://lesscss.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Find imports (hacky)
      imports = []
      imports.concat(content.scan(/^@import\s+(["'])([^\1]+?)\1;/))
      imports.concat(content.scan(/^@import\s+url\((["']?)([^)]+?)\1\);/))
      imported_filenames = imports.map do |i|
        i[1] =~ /\.(less|css)$/ ? i[1] : i[1] + '.less'
      end

      item_dir_path = Pathname.new(@item[:content_filename]).dirname.realpath
      cwd = Pathname.pwd # FIXME: ugly (get site dir instead)

      # Convert to items
      imported_items = imported_filenames.map do |filename|
        full_paths = []

        imported_pathname = Pathname.new(filename)

        # Find path relative to item
        absolute_pathname =
          if imported_pathname.relative?
            item_dir_path + imported_pathname
          else
            imported_pathname
          end
        if absolute_pathname.exist?
          full_paths << absolute_pathname.realpath
        end

        # Find path relative to working directory
        absolute_pathname =
          if imported_pathname.relative?
            cwd + imported_pathname
          else
            imported_pathname
          end
        if absolute_pathname.exist?
          full_paths << absolute_pathname.realpath
        end

        # Find matching item
        @items.find do |i|
          next if i[:content_filename].nil?
          item_path = Pathname.new(i[:content_filename]).realpath
          full_paths.any? { |fp| fp == item_path }
        end
      end.compact

      # Create dependencies
      depend_on(imported_items)

      # Add filename to load path
      paths = [File.dirname(@item[:content_filename])]
      on_main_fiber do
        parser = ::Less::Parser.new(paths: paths)
        parser.parse(content).to_css(params)
      end
    end
  end
end
