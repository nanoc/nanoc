module Nanoc

  class Compiler

    DEFAULT_CONFIG = {
      :output_dir => 'output'
    }

    DEFAULT_PAGE = {
      :layouts   => [ '<%= @content %>' ],
      :filters   => [],
      :order     => 0,
      :extension => 'html'
    }

    def initialize
      Nanoc.ensure_in_site
      
      @config = DEFAULT_CONFIG.merge(File.read_clean_yaml('config.yaml'))
      
      @global_page = DEFAULT_PAGE.merge(File.read_clean_yaml('meta.yaml'))
      unless @global_page[:layout].nil? 
        if @global_page[:layout] == 'none'
          @global_page[:layouts] = [ DEFAULT_PAGE[:layouts] ]
        else
          @global_page[:layouts] = [ @global_page[:layout] ]
        end
      end
      
      @default_layouts = @global_page[:layouts].collect { |l| File.read_file('layouts/' + l + '.erb') }
    end

    def run
      # Require files in lib/
      Dir.glob('lib/*.rb').each { |f| require f }

      # Compile pages
      pages = uncompiled_pages.sort { |x,y| x[:order].to_i <=> y[:order].to_i }
      pages = compile_pages(pages)

      # Put pages in their layouts
      pages.each do |page|
        # Compile layouts
        layouts = layouts_for_page(page)
        content = page[:content]
        layouts.each do |layout|
          content = layout.eruby(page.merge({ :page => page, :pages => pages, :content => content }))
        end
        
        # Write content
        FileManager.create_file(path_for_page(page)) { content }
      end
    end

    private

    def uncompiled_pages
      # Get all meta file names
      meta_filenames = Dir.glob('content/**/meta.yaml')

      # Read all meta files
      pages = meta_filenames.collect do |filename|
        # Get meta file
        page = @global_page.merge(File.read_clean_yaml(filename))
        page = page.merge({:path => filename.sub(/^content/, '').sub('meta.yaml', '')})

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

    def layouts_for_page(a_page)
      if a_page[:layouts] == @global_page[:layouts]
        @default_layouts
      else
        a_page[:layouts].collect { |l| File.read_file('layouts/' + l + '.erb') }
      end
    end

    def compile_pages(a_pages)
      pages = []

      a_pages.each do |page|
        # Read and filter page
        content = File.read_file(page[:_index_filename])
        content.filter!(page[:filters], :eruby_context => { :page => page, :pages => pages }) unless page[:filters].nil?

        # Store page
        pages << page.merge( { :content => content })
      end

      pages
    end

  end

end
