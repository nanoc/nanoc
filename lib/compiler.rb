module Nanoc
  class Compiler

    DEFAULT_PAGE = { :filters => [], :extension => 'html', :order => 0, :layout => "default" }

    def initialize
      Nanoc::Application.ensure_in_site
      Nanoc::Application.config.reload

      @global_page = DEFAULT_PAGE.merge(YAML.load_file_and_clean('meta.yaml'))
    end

    def run
      # Require all Ruby source files in lib/
      Dir['lib/*.rb'].each { |f| require f }

      # Compile all pages
      pages = compile_pages(uncompiled_pages)
      
      # Put pages in their layouts
      pages.each do |page|
        # Prepare layout content
        content = layout_for_page(page).eruby(page.merge({ :page => page, :pages => pages })) # fallback for nanoc 1.0
        
        # Write page with layout
        FileManager.create_file(path_for_page(page)) { content }
      end
    end

    private

    # Returns a list of uncompiled pages
    def uncompiled_pages
      # Get all meta files
      pages = Dir['content/**/meta.yaml'].collect do |filename|
        # Read the meta file
        page = @global_page.merge(YAML.load_file_and_clean(filename))
        page[:path] = filename.sub(/^content/, '').sub('meta.yaml', '')

        # Get the content filename
        content_filenames = Dir[filename.sub('meta.yaml', File.basename(File.dirname(filename)) + '.*')].reject { |f| f =~ /~$/ }
        content_filenames += Dir["#{File.dirname(filename)}/index.*"] # fallback for nanoc 1.0
        content_filenames.ensure_single('content files', File.dirname(filename))
        page[:_content_filename] = content_filenames[0]

        page
      end

      # Ignore drafts
      pages.reject! { |page| page[:is_draft] }

      # Sort pages by order and by path
      pages.sort! { |x,y| x[:order].to_i == y[:order].to_i ? x[:path] <=> y[:path] : x[:order].to_i <=> y[:order].to_i }

      pages
    end

    # Returns the layout for the given page
    def layout_for_page(a_page)
      a_page[:layout].nil? ? "<%= @page[:content] %>" : File.read("layouts/#{a_page[:layout]}.erb")
    end

    # Returns the path for the given page
    def path_for_page(a_page)
      Nanoc::Application.config[:output_dir] + ( a_page[:custom_path].nil? ? a_page[:path] + 'index.' + a_page[:extension] : a_page[:custom_path] )
    end

    # Compiles the given pages
    def compile_pages(a_pages)
      a_pages.inject([]) do |pages, page|
        content = File.read(page[:_content_filename]).filter(page[:filters], :eruby_context => { :page => page, :pages => pages })
        pages + [ page.merge( { :content => content, :_content_filename => nil }) ]
      end
    end

  end
end
