module Nanoc
  # @api private
  module Spec
    class HelperContext
      # @return [Nanoc::Int::DependencyTracker]
      attr_reader :dependency_tracker

      attr_reader :erbout

      # @param [Module] mod The helper module to create a context for
      def initialize(mod)
        @mod = mod

        @erbout = ''
        @rule_memory = {}
        @config = Nanoc::Int::Configuration.new.with_defaults
        @reps = Nanoc::Int::ItemRepRepo.new
        @items = Nanoc::Int::IdentifiableCollection.new(@config)
        @layouts = Nanoc::Int::IdentifiableCollection.new(@config)
        @dependency_tracker = Nanoc::Int::DependencyTracker.new(Object.new)
      end

      # Creates a new item and adds it to the site’s collection of items.
      #
      # @param [String] content The uncompiled item content
      #
      # @param [Hash] attributes A hash containing this item's attributes
      #
      # @param [Nanoc::Identifier, String] identifier This item's identifier
      #
      # @return [Nanoc::ItemWithRepsView] A view for the newly created item
      def create_item(content, attributes, identifier)
        item = Nanoc::Int::Item.new(content, attributes, identifier)
        @items << item
        Nanoc::ItemWithRepsView.new(item, view_context)
      end

      # Creates a new layout and adds it to the site’s collection of layouts.
      #
      # @param [String] content The raw layout content
      #
      # @param [Hash] attributes A hash containing this layout's attributes
      #
      # @param [Nanoc::Identifier, String] identifier This layout's identifier
      #
      # @return [Nanoc::ItemWithRepsView] A view for the newly created layout
      def create_layout(content, attributes, identifier)
        layout = Nanoc::Int::Layout.new(content, attributes, identifier)
        @layouts << layout
        Nanoc::LayoutView.new(layout, view_context)
      end

      # Creates a new representation for the given item.
      #
      # @param [Nanoc::ItemWithRepsView] item The item to create a represetation for
      #
      # @param [String] path The path of the `:last` snapshot of this item representation
      # @param [Symbol] rep The rep name to create
      def create_rep(item, path, rep = :default)
        rep = Nanoc::Int::ItemRep.new(item.unwrap, rep)
        rep.paths[:last] = path
        @reps << rep
        Nanoc::ItemRepView.new(rep, view_context)
      end

      # @return [Object] An object that includes the helper functions
      def helper
        mod = @mod
        klass = Class.new(Nanoc::Int::Context) { include mod }
        klass.new(assigns)
      end

      def item=(item)
        @item = item ? item.unwrap : nil
      end

      def item_rep=(item_rep)
        @item_rep = item_rep ? item_rep.unwrap : nil
      end

      # @return [Nanoc::MutableConfigView]
      def config
        assigns[:config]
      end

      # @return [Nanoc::ItemWithRepsView, nil]
      def item
        assigns[:item]
      end

      # @return [Nanoc::ItemRepView, nil]
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

      def rule_memory_for(obj)
        @rule_memory.fetch(obj, [])
      end

      def update_rule_memory(obj, memory)
        @rule_memory[obj] = memory
      end

      private

      def view_context
        Nanoc::ViewContext.new(
          reps: @reps,
          items: @items,
          dependency_tracker: @dependency_tracker,
          compilation_context: new_site.compiler.compilation_context,
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

          def memory_for(obj)
            @context.rule_memory_for(obj)
          end

          def snapshots_defs_for(_rep)
            [Nanoc::Int::SnapshotDef.new(:last)]
          end
        end.new(self)
      end

      def new_compiler_for(site)
        Nanoc::Int::CompilerLoader.new.load(site, action_provider: new_action_provider)
      end

      def new_site
        site = Nanoc::Int::Site.new(
          config: @config,
          code_snippets: [],
          items: @items,
          layouts: @layouts,
        )
        site.compiler = new_compiler_for(site)
        site
      end

      def assigns
        site = Nanoc::Int::Site.new(
          config: @config,
          code_snippets: [],
          items: @items,
          layouts: @layouts,
        )
        site.compiler = new_compiler_for(site)

        {
          config: Nanoc::MutableConfigView.new(@config, view_context),
          item_rep: @item_rep ? Nanoc::ItemRepView.new(@item_rep, view_context) : nil,
          item: @item ? Nanoc::ItemWithRepsView.new(@item, view_context) : nil,
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
