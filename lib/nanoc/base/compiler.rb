module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
  # representations.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    # FIXME compiler doesn't need to know about the site
    def initialize(site)
      @site = site
    end

    # Compiles (part of) the site and writes out the compiled page and asset
    # representations.
    #
    # +obj+:: The page or asset that should be compiled, along with their
    #         dependencies, or +nil+ if the entire site should be compiled.
    #
    # This method also accepts a few parameters:
    #
    # +:force+:: true if the rep should be compiled even if
    #                             it is not outdated, false if not. Defaults
    #                             to false.
    def run(objects=nil, params={})
      # Parse params
      force = params[:force] || false

      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Initialize
      @stack = []

      # Get pages and asset reps
      objects = @site.pages + @site.assets if objects.nil?
      reps = objects.map { |o| o.reps }.flatten

      # Compile everything
      reps.each { |rep| compile_rep(rep, force) }
    end

    # Compiles the given item representation. This method should not be called
    # directly; please use Nanoc::Compiler#run instead, and pass this item
    # representation's item as its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    #
    # +force+:: true if the item rep should be compiled even if it is not
    #                            outdated, false if not.
    def compile_rep(rep, force)
      # Reset compilation status
      rep.modified = false
      rep.created  = false

      # Don't compile if already compiled
      return if rep.compiled?

      # Skip unless outdated
      unless rep.outdated? or force
        Nanoc::NotificationCenter.post(:compilation_started, rep)
        Nanoc::NotificationCenter.post(:compilation_ended,   rep)
        return
      end

      # Check for recursive call
      if @stack.include?(rep)
        @stack.push(rep)
        raise Nanoc::Errors::RecursiveCompilationError.new
      end

      # Start
      @stack.push(rep)
      Nanoc::NotificationCenter.post(:compilation_started, rep)

      # Create raw and last snapshots if necessary
      rep.content[:raw]  ||= rep.item.content
      rep.content[:last] ||= rep.content[:raw]

      # Check if file will be created
      old_content = File.file?(rep.disk_path) ? File.read(rep.disk_path) : nil

      # Run instructions
      rep.processing_instructions.each do |instruction|
        case instruction[0]
          when :filter
            rep.filter(instruction[1], instruction[2])
          when :layout
            rep.layout(instruction[1])
          when :snapshot
            rep.snapshot(instruction[1])
          when :write
            rep.write
        end
      end

      # Update status
      rep.compiled = true
      unless rep.attribute_named(:skip_output)
        rep.created  = old_content.nil?
        rep.modified = rep.created ? true : old_content != rep.content[:last]
      end

      # Stop
      Nanoc::NotificationCenter.post(:compilation_ended, rep)
      @stack.pop
    end

  end

end
