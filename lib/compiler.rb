module Nanoc
  class Compiler

    DEFAULT_CONFIG = {
      :output_dir => 'output'
    }

    DEFAULT_PAGE = {
      :layout    => 'default',
      :filters   => [ ],
      :order     => 0,
      :extension => 'html'
    }

    def initialize
      Nanoc.ensure_in_site

      @config = DEFAULT_CONFIG.merge(YAML.load_file_and_clean('config.yaml'))
      @global_page = DEFAULT_PAGE.merge(YAML.load_file_and_clean('meta.yaml'))
      @global_page[:layout] = DEFAULT_PAGE[:layout] if @global_page[:layout] == 'none'
    end

    def run
      Dir.glob('lib/*.rb').each { |f| require f }

      pages = compile_pages(uncompiled_pages)
      pages.each do |page|
        content = File.read('layouts/' + page[:layout] + '.erb').eruby(page.merge({ :page => page, :pages => pages, :content => page[:content] }))
        FileManager.create_file(path_for_page(page)) { content }
      end
    end

    private

    def uncompiled_pages
      Dir.glob('content/**/meta.yaml').collect do |filename|
        page = @global_page.merge(YAML.load_file_and_clean(filename))
        page = page.merge({:path => filename.sub(/^content/, '').sub('meta.yaml', '')})
        page[:layout] = DEFAULT_PAGE[:layout] if page[:layout] == 'none'

        index_filenames = Dir.glob(File.dirname(filename) + '/index.*')
        index_filenames.ensure_single('index files', File.dirname(filename))
        page[:_index_filename] = index_filenames[0]

        page
      end.sort { |x,y| x[:order].to_i == y[:order].to_i ? x[:path] <=> y[:path] : x[:order].to_i <=> y[:order].to_i }
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
