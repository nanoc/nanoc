module Nanoc3

  # Nanoc3::Compiler is responsible for compiling a site's item
  # representations.
  class Compiler

    # The compilation stack. When the compiler begins compiling a rep, it will
    # be placed on the stack; when it is done compiling the rep, it will be
    # removed from the stack.
    attr_reader :stack

    # The list of compilation rules that will be used to compile items. This
    # array will be filled by Nanoc3::Site#load_data.
    attr_reader :item_compilation_rules

    # The list of mapping rules that will be used to give all items a path.
    # This array willb e filled by Nanoc3::Site#load_data.
    attr_reader :item_mapping_rules

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site

      @stack = []

      @item_compilation_rules  = []
      @layout_filter_mapping   = {}
    end

    # Compiles (part of) the site and writes out the compiled item
    # representations.
    #
    # +items+:: The items that should be compiled, along with their
    #           dependencies. Pass +nil+ if the entire site should be
    #           compiled.
    #
    # This method also accepts a few optional parameters:
    #
    # +:force+:: true if the rep should be compiled even if it is not
    #            outdated, false if not. Defaults to false.
    def run(items=nil, params={})
      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Get items and reps
      items ||= @site.items
      reps = items.map { |i| i.reps }.flatten

      # Mark all reps as outdated if necessary
      if params.has_key?(:force) && params[:force]
        reps.each { |r| r.force_outdated = true }
      end

      # Compile reps
      compile_reps(reps)
    end

    # Returns the compilation rule for the given rep.
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Returns the filter name for the given layout
    def filter_name_for_layout(layout)
      filter_name = nil
      @layout_filter_mapping.each_pair do |lr, fn|
        filter_name = fn if layout.identifier =~ lr
      end
      filter_name
    end

    # Adds an item compilation rule to the compiler.
    #
    # +identifier+:: The identifier for the item that should be compiled using
    #                this rule. Can contain the '*' wildcard, which matches
    #                zero or more characters.
    #
    # +rep_name+:: The name of the representation this compilation rule
    #              applies to.
    #
    # +block+:: A Proc that should be used to compile the matching items.
    def add_item_compilation_rule(identifier, rep_name, block)
      @item_compilation_rules << ItemRule.new(identifier_to_regex(identifier), rep_name, self, block)
    end

    # Adds a layout compilation rule to the compiler.
    #
    # +identifier+:: The identifier for the layout that should be compiled
    #                using this rule. Can contain the '*' wildcard, which
    #                matches zero or more characters.
    #
    # +filter_name+:: The name of the filter that should be used to compile
    #                 the matching layouts.
    def add_layout_compilation_rule(identifier, filter_name)
      @layout_filter_mapping[identifier_to_regex(identifier)] = filter_name
    end

  private

    # Compiles all item representations in the site.
    def compile_reps(reps)
      @stack.clear

      uncompiled_reps = reps.dup
      compiled_reps   = []

      until uncompiled_reps.empty?
        begin
          # Find an uncompiled rep
          rep = uncompiled_reps.shift

          # Check for recursive call
          if @stack.include?(rep)
            @stack.push(rep)
            raise Nanoc3::Errors::RecursiveCompilation.new
          end

          # Compile it
          @stack.push(rep)
          compile_rep(rep)
        rescue Nanoc3::Errors::UnmetDependency => e
          # Ensure the dependency is recompiled as soon as possible
          if e.rep
            # Add rep as 2nd element of queue
            uncompiled_reps.unshift(rep)

            # Add dependency as 1st element of queue
            uncompiled_reps.delete(e.rep)
            uncompiled_reps.unshift(e.rep)
          else
            uncompiled_reps << rep
          end
        else
          # Compilation was successful, so clear the stack and mark the rep as compiled
          compiled_reps << rep
          @stack.clear
        end
      end
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # Nanoc3::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    def compile_rep(rep)
      # Skip unless outdated
      unless rep.outdated?
        Nanoc3::NotificationCenter.post(:compilation_started, rep)
        Nanoc3::NotificationCenter.post(:compilation_ended,   rep)
        return
      end

      # Start
      Nanoc3::NotificationCenter.post(:compilation_started, rep)

      # Apply matching rule
      compilation_rule_for(rep).apply_to(rep)
      rep.compiled = true

      # Stop
      Nanoc3::NotificationCenter.post(:compilation_ended, rep)
    end

    # Converts the given identifier, which can contain the '*' wildcard, to a regex.
    # For example, 'foo/*/bar' is transformed into /^foo\/(.*?)\/bar$/.
    def identifier_to_regex(identifier)
      if identifier.is_a? String
        /^#{identifier.gsub('*', '(.*?)')}$/
      else
        identifier
      end
    end

  end

end
