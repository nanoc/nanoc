# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Less < Nanoc::Filter
    identifier :less

    requires 'less'

    # Runs the content through [LESS](http://lesscss.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params = {})
      # Create dependencies
      imported_filenames = imported_filenames_from(content)
      imported_items = imported_filenames_to_items(imported_filenames)
      depend_on(imported_items)

      # Add filename to load path
      paths = [File.dirname(@item[:content_filename])]
      on_main_fiber do
        parser = ::Less::Parser.new(paths: paths)
        parser.parse(content).to_css(params)
      end
    end

    def imported_filenames_from(content)
      imports = []
      imports.concat(content.scan(/^@import\s+(["'])([^\1]+?)\1;/))
      imports.concat(content.scan(/^@import\s+url\((["']?)([^)]+?)\1\);/))

      imports.map { |i| i[1] =~ /\.(less|css)$/ ? i[1] : i[1] + '.less' }
    end

    def imported_filenames_to_items(imported_filenames)
      item_dir_path = Pathname.new(@item[:content_filename]).dirname.realpath
      cwd = Pathname.pwd # FIXME: ugly (get site dir instead)

      imported_filenames.map do |filename|
        full_paths = Set.new

        imported_pathname = Pathname.new(filename)
        full_paths << find_file(imported_pathname, item_dir_path)
        full_paths << find_file(imported_pathname, cwd)

        # Find matching item
        @items.find do |i|
          next if i[:content_filename].nil?
          item_path = Pathname.new(i[:content_filename]).realpath
          full_paths.any? { |fp| fp == item_path }
        end
      end.compact
    end

    # @param [Pathname] pathname Pathname of the file to find. Can be relative or absolute.
    #
    # @param [Pathname] root_pathname Directory pathname from which the search will start.
    #
    # @return [String, nil] A string containing the full path if a file is found, otherwise nil.
    def find_file(pathname, root_pathname)
      absolute_pathname =
        if pathname.relative?
          root_pathname + pathname
        else
          pathname
        end

      if absolute_pathname.exist?
        absolute_pathname.realpath
      else
        nil
      end
    end
  end
end
