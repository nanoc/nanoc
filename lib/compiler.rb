module Nanoc

  class Compiler

    DEFAULT_CONFIG = {
      :output_dir => 'output'
    }

    DEFAULT_PAGE = {
      :layout    => '<%= @content %>',
      :filters   => [],
      :order     => 0,
      :extension => 'html'
    }

    def initialize
      Nanoc.ensure_in_site
      
      @config         = DEFAULT_CONFIG.merge(File.read_clean_yaml('config.yaml'))
      @global_page    = DEFAULT_PAGE.merge(File.read_clean_yaml('meta.yaml'))
      @default_layout = File.read_file('layouts/' + @global_page[:layout] + '.erb')
    end

    def run
      Nanoc.ensure_in_site
      
      # Require files in lib/
      Dir.glob('lib/*.rb').each { |f| require f }

      # Compile pages
      pages = uncompiled_pages.sort { |x,y| x[:order].to_i <=> y[:order].to_i }
      pages = compile_pages(pages)

      # Put pages in their layout
      pages.each do |page|
        content_with_layout = layout_for_page(page).eruby(page.merge({ :pages => pages }))
        FileManager.create_file(path_for_page(page)) { content_with_layout }
      end
    end

    private

    def uncompiled_pages
      # Get all meta file names
      meta_filenames = Dir.glob('content/**/meta.yaml')

      # Read all meta files
      pages = meta_filenames.collect do |filename|
        # Get meta file
        page = @global_page.merge(File.read_clean_yaml(filename)).merge({:path => filename.sub(/^content/, '').sub('meta.yaml', '')})

        # Get index filename
        index_filenames = Dir.glob(File.dirname(filename) + '/index.*')
        index_filenames.ensure_single('index files', File.dirname(filename))
        page[:_index_filename] = index_filenames[0]

        page
      end
    end

    def path_for_page(a_page)
      if a_page[:custom_path].nil?
        @config[:output_dir] + a_page[:path] + 'index.' + a_page[:extension]
      else
        @config[:output_dir] + a_page[:custom_path]
      end
    end

    def layout_for_page(a_page)
      if a_page[:layout] == 'none'
        '<%= @content %>'
      elsif @global_page[:layout] != a_page[:layout]
        File.read_file('layouts/' + a_page[:layout] + '.erb')
      else
        @default_layout
      end
    end

    def compile_pages(a_pages)
      pages = []

      a_pages.each do |page|
        # Read and filter page
        content = File.read_file(page[:_index_filename])
        content.filter!(page[:filters], :eruby_context => { :pages => pages }) unless page[:filters].nil?

        # Store page
        pages << page.merge( { :content => content })
      end

      pages
    end

  end

end
