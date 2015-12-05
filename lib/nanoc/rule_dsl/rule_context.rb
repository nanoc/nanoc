module Nanoc::RuleDSL
  # Provides a context in which compilation and routing rules can be executed.
  # It provides access to the item representation that is being compiled or
  # routed.
  #
  # @api private
  class RuleContext < Nanoc::Int::Context
    # @param [Nanoc::Int::ItemRep] rep
    # @param [Nanoc::Int::Site] site
    # @param [Nanoc::Int::Executor, Nanoc::RuleDSL::RecordingExecutor] executor
    # @param [Nanoc::ViewContext] view_context
    def initialize(rep:, site:, executor:, view_context:)
      @_executor = executor

      super({
        item: Nanoc::ItemView.new(rep.item, view_context),
        rep: Nanoc::ItemRepView.new(rep, view_context),
        item_rep: Nanoc::ItemRepView.new(rep, view_context),
        items: Nanoc::ItemCollectionView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
        site: Nanoc::SiteView.new(site, view_context),
      })
    end

    # Filters the current representation (calls {Nanoc::Int::ItemRep#filter} with
    # the given arguments on the rep).
    #
    # @see Nanoc::Int::ItemRep#filter
    #
    # @param [Symbol] filter_name The name of the filter to run the item
    #   representations' content through
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method
    #
    # @return [void]
    def filter(filter_name, filter_args = {})
      @_executor.filter(rep.unwrap, filter_name, filter_args)
    end

    # Layouts the current representation (calls {Nanoc::Int::ItemRep#layout} with
    # the given arguments on the rep).
    #
    # @see Nanoc::Int::ItemRep#layout
    #
    # @param [String] layout_identifier The identifier of the layout the item
    #   should be laid out with
    #
    # @return [void]
    def layout(layout_identifier, extra_filter_args = nil)
      @_executor.layout(rep.unwrap, layout_identifier, extra_filter_args)
    end

    # Creates a snapshot of the current compiled item content. Calls
    # {Nanoc::Int::ItemRep#snapshot} with the given arguments on the rep.
    #
    # @see Nanoc::Int::ItemRep#snapshot
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @param [String, nil] path
    #
    # @return [void]
    def snapshot(snapshot_name, path: nil)
      @_executor.snapshot(rep.unwrap, snapshot_name, path: path)
    end

    # Creates a snapshot named :last the current compiled item content, with
    # the given path. This is a convenience method for {#snapshot}.
    #
    # @see #snapshot
    #
    # @param [String] path
    #
    # @return [void]
    def write(path)
      snapshot(:last, path: path)
    end
  end
end
