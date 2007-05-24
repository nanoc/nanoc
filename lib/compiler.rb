module Nanoc
  class Compiler

    DEFAULT_PAGE    = { :filters => [], :extension => 'html', :order => 0, :layout => "default" }

    def initialize
      Nanoc.ensure_in_site

      @global_page = DEFAULT_PAGE.merge(YAML.load_file_and_clean('meta.yaml'))
    end

    def run
      Dir['lib/*.rb'].each { |f| require f }

      pages = compile_pages(uncompiled_pages)
      pages.each do |page|
        content = (page[:layout].nil? ? "<%= @page[:content] %>" : File.read("layouts/#{page[:layout]}.erb")).eruby(page.merge({ :page => page, :pages => pages })) # fallback for nanoc 1.0
        FileManager.create_file(path_for_page(page)) { content }
      end
    end

    private

    def uncompiled_pages
      Dir['content/**/meta.yaml'].collect do |filename|
        page = @global_page.merge(YAML.load_file_and_clean(filename))
        page[:path] = filename.sub(/^content/, '').sub('meta.yaml', '')

        content_filenames = Dir[filename.sub('meta.yaml', File.basename(File.dirname(filename)) + '.*')].reject { |f| f =~ /~$/ }
        content_filenames += Dir["#{File.dirname(filename)}/index.*"] # fallback for nanoc 1.0
        content_filenames.ensure_single('content files', File.dirname(filename))
        page[:_content_filename] = content_filenames[0]

        page
      end.compact.reject { |page| page[:is_draft] }.sort do |x,y|
        x[:order].to_i == y[:order].to_i ? x[:path] <=> y[:path] : x[:order].to_i <=> y[:order].to_i
      end
    end

    def path_for_page(a_page)
      Nanoc.config[:output_dir] + ( a_page[:custom_path].nil? ? a_page[:path] + 'index.' + a_page[:extension] : a_page[:custom_path] )
    end

    def compile_pages(a_pages)
      a_pages.inject([]) do |pages, page|
        content = File.read(page[:_content_filename]).filter(page[:filters], :eruby_context => { :page => page, :pages => pages })
        pages + [ page.merge( { :content => content, :_content_filename => nil }) ]
      end
    end

  end
end
