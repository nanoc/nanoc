# frozen_string_literal: true

module Nanoc
  # @api private
  module Spec
    module Helper
      def chdir(dir)
        here = Dir.getwd
        Dir.chdir(dir)
        yield
      ensure
        Dir.chdir(here)
      end

      def on_windows?
        Nanoc.on_windows?
      end

      def command?(cmd)
        which, null = on_windows? ? %w[where NUL] : ['which', '/dev/null']
        system("#{which} #{cmd} > #{null} 2>&1")
      end

      def skip_unless_have_command(cmd)
        skip "Could not find external command \"#{cmd}\"" unless command?(cmd)
      end

      def skip_unless_gem_available(gem)
        require gem
      rescue LoadError
        skip "Could not load gem \"#{gem}\""
      end

      def sleep_until(max: 3.0)
        start = Time.now
        loop do
          diff = (Time.now - start).to_f
          if diff > max
            raise "Waited for #{diff}s for condition to become true, but it never did"
          end

          break if yield

          sleep 0.1
        end
      end
    end

    class HelperContext
      # @return [Nanoc::Int::DependencyTracker]
      attr_reader :dependency_tracker

      attr_reader :erbout

      # @param [Module] mod The helper module to create a context for
      def initialize(mod)
        @mod = mod

        @erbout = +''
        @action_sequence = {}
        @config = Nanoc::Int::Configuration.new(dir: Dir.getwd).with_defaults
        @reps = Nanoc::Int::ItemRepRepo.new
        @items = Nanoc::Int::ItemCollection.new(@config)
        @layouts = Nanoc::Int::LayoutCollection.new(@config)
        @dependency_tracker = Nanoc::Int::DependencyTracker.new(Object.new)
        @compiled_content_store = Nanoc::Int::CompiledContentStore.new
        @action_provider = new_action_provider
      end

      # Creates a new item and adds it to the site’s collection of items.
      #
      # @param [String] content The uncompiled item content
      #
      # @param [Hash] attributes A hash containing this item's attributes
      #
      # @param [Nanoc::Core::Identifier, String] identifier This item's identifier
      #
      # @return [Nanoc::CompilationItemView] A view for the newly created item
      def create_item(content, attributes, identifier)
        item = Nanoc::Int::Item.new(content, attributes, identifier)
        @items = @items.add(item)
        self
      end

      # Creates a new layout and adds it to the site’s collection of layouts.
      #
      # @param [String] content The raw layout content
      #
      # @param [Hash] attributes A hash containing this layout's attributes
      #
      # @param [Nanoc::Core::Identifier, String] identifier This layout's identifier
      #
      # @return [Nanoc::CompilationItemView] A view for the newly created layout
      def create_layout(content, attributes, identifier)
        layout = Nanoc::Int::Layout.new(content, attributes, identifier)
        @layouts = @layouts.add(layout)
        self
      end

      # Creates a new representation for the given item.
      #
      # @param [Nanoc::CompilationItemView] item The item to create a represetation for
      #
      # @param [String] path The path of the `:last` snapshot of this item representation
      # @param [Symbol] rep The rep name to create
      def create_rep(item, path, rep = :default)
        rep = Nanoc::Int::ItemRep.new(item._unwrap, rep)
        rep.paths[:last] = [path]
        @reps << rep
        self
      end

      # @return [Object] An object that includes the helper functions
      def helper
        mod = @mod
        klass = Class.new(Nanoc::Core::Context) { include mod }
        klass.new(assigns)
      end

      def item=(item)
        @item = item ? item._unwrap : nil
      end

      def item_rep=(item_rep)
        @item_rep = item_rep ? item_rep._unwrap : nil
      end

      # @return [Nanoc::MutableConfigView]
      def config
        assigns[:config]
      end

      # @return [Nanoc::CompilationItemView, nil]
      def item
        assigns[:item]
      end

      # @return [Nanoc::BasicItemRepView, nil]
      def item_rep
        assigns[:item_rep]
      end

      # @return [Nanoc::ItemCollectionWithRepsView]
      def items
        assigns[:items]
      end

      # @return [Nanoc::LayoutCollectionView]
      def layouts
        assigns[:layouts]
      end

      def action_sequence_for(obj)
        @action_sequence.fetch(obj, [])
      end

      def update_action_sequence(obj, memory)
        @action_sequence[obj] = memory
      end

      def compiled_content_store
        view_context.compiled_content_store
      end

      private

      def view_context
        compilation_context =
          Nanoc::Int::CompilationContext.new(
            action_provider: @action_provider,
            reps: @reps,
            site: @site,
            compiled_content_cache: :__compiled_content_cache,
            compiled_content_store: @compiled_content_store,
          )

        Nanoc::ViewContextForCompilation.new(
          reps: @reps,
          items: @items,
          dependency_tracker: @dependency_tracker,
          compilation_context: compilation_context,
          compiled_content_store: @compiled_content_store,
        )
      end

      def new_action_provider
        Class.new(Nanoc::Int::ActionProvider) do
          def self.for(_context)
            raise NotImplementedError
          end

          def initialize(context)
            @context = context
          end

          def rep_names_for(_item)
            [:default]
          end

          def action_sequence_for(obj)
            @context.action_sequence_for(obj)
          end

          def snapshots_defs_for(_rep)
            [Nanoc::Int::SnapshotDef.new(:last, binary: false)]
          end
        end.new(self)
      end

      def new_compiler_for(site)
        Nanoc::Int::CompilerLoader.new.load(site, action_provider: @action_provider)
      end

      def site
        @_site ||=
          Nanoc::Int::Site.new(
            config: @config,
            code_snippets: [],
            data_source: Nanoc::Int::InMemDataSource.new(@items, @layouts),
          )
      end

      def assigns
        {
          config: Nanoc::MutableConfigView.new(@config, view_context),
          item_rep: @item_rep ? Nanoc::CompilationItemRepView.new(@item_rep, view_context) : nil,
          item: @item ? Nanoc::CompilationItemView.new(@item, view_context) : nil,
          items: Nanoc::ItemCollectionWithRepsView.new(@items, view_context),
          layouts: Nanoc::LayoutCollectionView.new(@layouts, view_context),
          _erbout: @erbout,
        }
      end
    end

    module HelperHelper
      def ctx
        @_ctx ||= HelperContext.new(described_class)
      end

      def helper
        @_helper ||= ctx.helper
      end
    end
  end
end
