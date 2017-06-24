# frozen_string_literal: true

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

        @erbout = String.new
        @action_sequence = {}
        @config = Nanoc::Int::Configuration.new.with_defaults
        @reps = Nanoc::Int::ItemRepRepo.new
        @items = Nanoc::Int::ItemCollection.new(@config)
        @layouts = Nanoc::Int::LayoutCollection.new(@config)
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
        @items = @items.add(item)
        self
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
        @layouts = @layouts.add(layout)
        self
      end

      # Creates a new representation for the given item.
      #
      # @param [Nanoc::ItemWithRepsView] item The item to create a represetation for
      #
      # @param [String] path The path of the `:last` snapshot of this item representation
      # @param [Symbol] rep The rep name to create
      def create_rep(item, path, rep = :default)
        rep = Nanoc::Int::ItemRep.new(item.unwrap, rep)
        rep.paths[:last] = [path]
        @reps << rep
        self
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

      def action_sequence_for(obj)
        @action_sequence.fetch(obj, [])
      end

      def update_action_sequence(obj, memory)
        @action_sequence[obj] = memory
      end

      def snapshot_repo
        view_context.snapshot_repo
      end

      private

      def view_context
        Nanoc::ViewContext.new(
          reps: @reps,
          items: @items,
          dependency_tracker: @dependency_tracker,
          compilation_context: site.compiler.compilation_context,
          snapshot_repo: site.compiler.compilation_context.snapshot_repo,
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
        Nanoc::Int::CompilerLoader.new.load(site, action_provider: new_action_provider)
      end

      def site
        @_site ||= begin
          site = Nanoc::Int::Site.new(
            config: @config,
            code_snippets: [],
            data_source: Nanoc::Int::InMemDataSource.new(@items, @layouts),
          )
          site.compiler = new_compiler_for(site)
          site
        end
      end

      def assigns
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
