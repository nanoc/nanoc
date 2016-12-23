module Nanoc::Int
  # Responsible for compiling a site’s item representations.
  #
  # The compilation process makes use of notifications (see
  # {Nanoc::Int::NotificationCenter}) to track dependencies between items,
  # layouts, etc. The following notifications are used:
  #
  # * `compilation_started` — indicates that the compiler has started
  #   compiling this item representation. Has one argument: the item
  #   representation itself. Only one item can be compiled at a given moment;
  #   therefore, it is not possible to get two consecutive
  #   `compilation_started` notifications without also getting a
  #   `compilation_ended` notification in between them.
  #
  # * `compilation_ended` — indicates that the compiler has finished compiling
  #   this item representation (either successfully or with failure). Has one
  #   argument: the item representation itself.
  #
  # @api private
  class Compiler
    # Coordinates the compilation of a single item rep.
    class Single
      include Nanoc::Int::ContractsSupport

      # TODO: The reference to compiler should go away.

      def initialize(dependency_store:, compiled_content_cache:, compiler:)
        @dependency_store = dependency_store
        @compiled_content_cache = compiled_content_cache
        @compiler = compiler # TODO: remove me
      end

      contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
      def compile(rep, is_outdated:)
        fiber = fiber_for(rep, is_outdated: is_outdated)
        while fiber.alive?
          Nanoc::Int::NotificationCenter.post(:compilation_started, rep)
          res = fiber.resume

          case res
          when Nanoc::Int::Errors::UnmetDependency
            Nanoc::Int::NotificationCenter.post(:compilation_suspended, rep, res)
            raise(res)
          when Proc
            fiber.resume(res.call)
          else
            # TODO: raise
          end
        end

        Nanoc::Int::NotificationCenter.post(:compilation_ended, rep)
      end

      private

      contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => Fiber
      def fiber_for(rep, is_outdated:)
        @fibers ||= {}

        @fibers[rep] ||=
          Fiber.new do
            begin
              dependency_tracker = Nanoc::Int::DependencyTracker.new(@dependency_store)
              dependency_tracker.enter(rep.item)

              if can_reuse_content_for_rep?(rep, is_outdated: is_outdated)
                Nanoc::Int::NotificationCenter.post(:cached_content_used, rep)
                rep.snapshot_contents = @compiled_content_cache[rep]
              else
                recalculate_content_for_rep(rep, dependency_tracker)
              end

              rep.compiled = true
              @compiled_content_cache[rep] = rep.snapshot_contents

              @fibers.delete(rep)
            ensure
              dependency_tracker.exit
            end
          end

        @fibers[rep]
      end

      contract Nanoc::Int::ItemRep, C::Named['Nanoc::Int::DependencyTracker'] => C::Any
      def recalculate_content_for_rep(rep, dependency_tracker)
        executor = Nanoc::Int::Executor.new(@compiler, dependency_tracker)

        @compiler.action_provider.memory_for(rep).each do |action|
          case action
          when Nanoc::Int::ProcessingActions::Filter
            executor.filter(rep, action.filter_name, action.params)
          when Nanoc::Int::ProcessingActions::Layout
            executor.layout(rep, action.layout_identifier, action.params)
          when Nanoc::Int::ProcessingActions::Snapshot
            executor.snapshot(rep, action.snapshot_name, final: action.final?, path: action.path)
          else
            raise Nanoc::Int::Errors::InternalInconsistency, "unknown action #{action.inspect}"
          end
        end
      end

      contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Bool
      def can_reuse_content_for_rep?(rep, is_outdated:)
        !is_outdated && !@compiled_content_cache[rep].nil?
      end
    end

    include Nanoc::Int::ContractsSupport

    # @api private
    attr_reader :site

    # @api private
    attr_reader :compiled_content_cache

    # @api private
    attr_reader :checksum_store

    # @api private
    attr_reader :rule_memory_store

    # @api private
    attr_reader :action_provider

    # @api private
    attr_reader :dependency_store

    # @api private
    attr_reader :outdatedness_checker

    # @api private
    attr_reader :reps

    def initialize(site, compiled_content_cache:, checksum_store:, rule_memory_store:, action_provider:, dependency_store:, outdatedness_checker:, reps:)
      @site = site

      @compiled_content_cache = compiled_content_cache
      @checksum_store         = checksum_store
      @rule_memory_store      = rule_memory_store
      @dependency_store       = dependency_store
      @outdatedness_checker   = outdatedness_checker
      @reps                   = reps
      @action_provider        = action_provider
    end

    def run_all
      @action_provider.preprocess(@site)
      build_reps
      prune
      run
      @action_provider.postprocess(@site, @reps)
    end

    def run
      load_stores
      @site.freeze

      compile_reps
      store
    ensure
      Nanoc::Int::TempFilenameFactory.instance.cleanup(
        Nanoc::Filter::TMP_BINARY_ITEMS_DIR,
      )
      Nanoc::Int::TempFilenameFactory.instance.cleanup(
        Nanoc::Int::ItemRepWriter::TMP_TEXT_ITEMS_DIR,
      )
    end

    def load_stores
      # FIXME: icky hack to update the dependency/checksum store’s list of objects
      # (does not include preprocessed objects otherwise)
      dependency_store.objects = site.items.to_a + site.layouts.to_a
      checksum_store.objects = site.items.to_a + site.layouts.to_a + site.code_snippets + [site.config]

      stores.each(&:load)
    end

    # Store the modified helper data used for compiling the site.
    #
    # @return [void]
    def store
      # Calculate rule memory
      (@reps.to_a + @site.layouts.to_a).each do |obj|
        rule_memory_store[obj] = action_provider.memory_for(obj).serialize
      end

      # Calculate checksums
      objects_to_checksum =
        site.items.to_a + site.layouts.to_a + site.code_snippets + [site.config]
      objects_to_checksum.each { |obj| checksum_store.add(obj) }

      # Store
      stores.each(&:store)
    end

    def build_reps
      builder = Nanoc::Int::ItemRepBuilder.new(
        site, action_provider, @reps
      )
      builder.run
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation for which the
    #   assigns should be fetched
    #
    # @return [Hash] The assigns that should be used in the next filter/layout
    #   operation
    #
    # @api private
    def assigns_for(rep, dependency_tracker)
      content_or_filename_assigns =
        if rep.binary?
          { filename: rep.snapshot_contents[:last].filename }
        else
          { content: rep.snapshot_contents[:last].string }
        end

      view_context = create_view_context(dependency_tracker)

      content_or_filename_assigns.merge(
        item: Nanoc::ItemWithRepsView.new(rep.item, view_context),
        rep: Nanoc::ItemRepView.new(rep, view_context),
        item_rep: Nanoc::ItemRepView.new(rep, view_context),
        items: Nanoc::ItemCollectionWithRepsView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
      )
    end

    def create_view_context(dependency_tracker)
      Nanoc::ViewContext.new(
        reps: @reps,
        items: @site.items,
        dependency_tracker: dependency_tracker,
        compiler: self,
      )
    end

    # @api private
    def filter_name_and_args_for_layout(layout)
      mem = action_provider.memory_for(layout)
      if mem.nil? || mem.size != 1 || !mem[0].is_a?(Nanoc::Int::ProcessingActions::Filter)
        raise Nanoc::Int::Errors::UndefinedFilterForLayout.new(layout)
      end
      [mem[0].filter_name, mem[0].params]
    end

    private

    def prune
      if site.config[:prune][:auto_prune]
        Nanoc::Pruner.new(site.config, reps, exclude: prune_config_exclude).run
      end
    end

    def prune_config
      site.config[:prune] || {}
    end

    def prune_config_exclude
      prune_config[:exclude] || {}
    end

    def compile_reps
      # Assign snapshots
      @reps.each do |rep|
        rep.snapshot_defs = action_provider.snapshots_defs_for(rep)
      end

      # Find item reps to compile
      outdated_reps = Set.new(@reps.select { |r| outdatedness_checker.outdated?(r) })

      # Reset dependencies for outdated items
      outdated_items = outdated_reps.map(&:item).uniq
      outdated_items.each { |i| @dependency_store.forget_dependencies_for(i) }

      # Compile reps
      selector = Nanoc::Int::ItemRepSelector.new(outdated_reps)
      selector.each do |rep|
        handle_errors_while(rep) { compile_rep(rep, is_outdated: outdated_reps.include?(rep)) }
      end
    end

    def handle_errors_while(item_rep)
      yield
    rescue => e
      raise Nanoc::Int::Errors::CompilationError.new(e, item_rep)
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # {Nanoc::Int::Compiler#run} instead, and pass this item representation's item
    # as its first argument.
    #
    # @param [Nanoc::Int::ItemRep] rep The rep that is to be compiled
    #
    # @return [void]
    def compile_rep(rep, is_outdated: true)
      # TODO: remove is_outdated arg fallback
      single.compile(rep, is_outdated: is_outdated)
    end

    def single
      @_single ||= Single.new(
        dependency_store: @dependency_store,
        compiled_content_cache: compiled_content_cache,
        compiler: self,
      )
    end

    # Returns all stores that can load/store data that can be used for
    # compilation.
    def stores
      [
        checksum_store,
        compiled_content_cache,
        @dependency_store,
        rule_memory_store,
      ]
    end
  end
end
