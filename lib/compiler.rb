module Nanoc
  class Compiler

    DEFAULT_CONFIG = {
      :output_dir => 'output'
    }

    DEFAULT_PAGE = {
      :layouts   => [ 'default' ],
      :filters   => [ ],
      :order     => 0,
      :extension => 'html'
    }

    def initialize
      Nanoc.ensure_in_site

      @config = DEFAULT_CONFIG.merge(File.read_clean_yaml('config.yaml'))
      @global_page = DEFAULT_PAGE.merge(File.read_clean_yaml('meta.yaml'))
      unless @global_page[:layout].nil?
        @global_page[:layouts] = ( @global_page[:layout] == 'none' ? [ DEFAULT_PAGE[:layouts] ] : [ @global_page[:layout] ] )
      end
    end

    def run
      Dir.glob('lib/*.rb').each { |f| require f }
      pages = compile_pages(uncompiled_pages.sort { |x,y| x[:order].to_i <=> y[:order].to_i })
      pages.each do |page|
        content = page[:layouts].collect { |name| File.read('layouts/' + name + '.erb') }.inject(page[:content]) do |content, layout|
          layout.eruby(page.merge({ :page => page, :pages => pages, :content => content }))
        end
        FileManager.create_file(path_for_page(page)) { content }
      end
    end

    private

    def uncompiled_pages
      Dir.glob('content/**/meta.yaml').collect do |filename|
        page = @global_page.merge(File.read_clean_yaml(filename))
        page = page.merge({:path => filename.sub(/^content/, '').sub('meta.yaml', '')})

        index_filenames = Dir.glob(File.dirname(filename) + '/index.*')
        index_filenames.ensure_single('index files', File.dirname(filename))
        page[:_index_filename] = index_filenames[0]

        page
      end
    end

    def path_for_page(a_page)
      @config[:output_dir] + ( a_page[:custom_path].nil? ? a_page[:path] + 'index.' + a_page[:extension] : a_page[:custom_path] )
    end

    def compile_pages(a_pages)
      a_pages.inject([]) do |pages, page|
        content = File.read(page[:_index_filename]).filter(page[:filters], :eruby_context => { :page => page, :pages => pages })
        pages + [ page.merge( { :content => content }) ]
      end
    end

  end
end
