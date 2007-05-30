module Nanoc
  class Compiler

    PAGE_DEFAULTS = {
      :filters    => [],
      :extension  => 'html',
      :order      => 0,
      :layout     => 'default'
    }

    def initialize
      Nanoc::Application.ensure_in_site
      Nanoc::Configuration.reload

      @global_page = PAGE_DEFAULTS.merge(YAML.load_file_and_clean('meta.yaml'))
    end

    def run
      # Require all Ruby source files in lib/
      Dir['lib/*.rb'].each { |f| require f }

      # Copy assets to output directory
      copy_assets

      # Compile all pages
      pages = compile_pages(uncompiled_pages)

      # Put pages in their layouts
      pages.each do |page|
        # Prepare layout content
        content = nil
        begin
          context = { :page => page.merge(:_content_filename => nil), :pages => pages }
          content = layout_for_page(page).eruby(context)
        rescue Exception => e
          $stderr.puts "Exception occured while layouting page '#{page[:_content_filename]}' in layout '#{page[:layout]}':" unless $quiet
          $stderr.puts e.backtrace.join("\n") unless $quiet
          exit
        end

        # Write page with layout
        FileManager.create_file(path_for_page(page)) { content }
      end
    end

    private

    def copy_assets
      `cp -R assets/* output/` if File.directory?('assets') and !Dir['assets/*'].empty?
    end

    # Returns a list of uncompiled pages
    def uncompiled_pages
      # Read all old style meta files
      pages_old_style = Dir['content/**/meta.yaml'].collect do |filename|
        # Read the meta file
        page = @global_page.merge(YAML.load_file_and_clean(filename))
        page[:path] = filename.sub(/^content/, '').sub('meta.yaml', '')

        # Get the content filename
        content_filenames = Dir[filename.sub('meta.yaml', File.basename(File.dirname(filename)) + '.*')]
        content_filenames += Dir["#{File.dirname(filename)}/index.*"] # fallback for nanoc 1.0
        content_filenames.reject! { |f| f =~ /~$/ } # Ignore backup files
        content_filenames.ensure_single('content files', File.dirname(filename))
        page[:_content_filename] = content_filenames[0]

        page
      end

      # Read all new style meta files
      pages_new_style = Dir['content/**/*.yaml'].reject { |p| p =~ /\/meta\.yaml$/ }.collect do |filename|
        # Read the meta file
        page = @global_page.merge(YAML.load_file_and_clean(filename))

        # Get the page path
        if filename =~ /index\.yaml$/
          page[:path] = filename.sub(/^content/, '').sub(/index.yaml$/, '')
        else
          page[:path] = filename.sub(/^content/, '').sub(/\/(.+?)\.yaml$/, '/\1/')
        end

        # Get the content filename
        content_filenames = Dir[filename.sub('.yaml', '.*')].reject { |f| f =~ /\.yaml$|~$/ }
        content_filenames.ensure_single('content files', File.dirname(filename))
        page[:_content_filename] = content_filenames[0]

        page
      end

      # Combine pages
      pages = pages_old_style + pages_new_style

      # Ignore drafts
      pages.reject! { |page| page[:is_draft] }

      # Sort pages by order and by path
      pages.sort! do |x,y|
        if x[:order].to_i == y[:order].to_i
          x[:path] <=> y[:path]
        else
          x[:order].to_i <=> y[:order].to_i
        end
      end

      pages
    end

    # Returns the layout for the given page
    def layout_for_page(a_page)
      if a_page[:layout].nil?
        "<%= @page[:content] %>"
      else
        File.read("layouts/#{a_page[:layout]}.erb")
      end
    end

    # Returns the path for the given page
    def path_for_page(a_page)
      if a_page[:custom_path].nil?
        Nanoc::Configuration[:output_dir] + a_page[:path] + 'index.' + a_page[:extension]
      else
        Nanoc::Configuration[:output_dir] + a_page[:custom_path]
      end
    end

    # Compiles the given pages and returns the compiled pages
    def compile_pages(a_pages)
      a_pages.inject([]) do |pages, page|
        # Read page
        content = File.read(page[:_content_filename])

        # Filter page
        begin
          content = content.filter(page[:filters], :eruby_context => { :page => page, :pages => pages })
        rescue Exception => e
          $stderr.puts 'Exception occured while compiling ' + page[:_content_filename] + ':' unless $quiet
          $stderr.puts e.backtrace.join("\n") unless $quiet
          exit
        end

        # Create compiled page
        compiled_page = page.merge( :content => content )

        # Remember page
        pages + [ compiled_page ]
      end
    end

  end
end
