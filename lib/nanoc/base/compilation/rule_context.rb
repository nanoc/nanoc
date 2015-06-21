module Nanoc::Int
  # Provides a context in which compilation and routing rules can be executed.
  # It provides access to the item representation that is being compiled or
  # routed.
  #
  # @api private
  class RuleContext < Nanoc::Int::Context
    # @option params [Nanoc::Int::ItemRep] :rep
    # @option params [Nanoc::Int::Site] :site
    def initialize(params = {})
      rep = params.fetch(:rep)
      site = params.fetch(:site)
      @_executor = params.fetch(:executor)

      super({
        item: Nanoc::ItemView.new(rep.item),
        rep: Nanoc::ItemRepView.new(rep),
        item_rep: Nanoc::ItemRepView.new(rep),
        items: Nanoc::ItemCollectionView.new(site.items),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts),
        config: Nanoc::ConfigView.new(site.config),
        site: Nanoc::SiteView.new(site),
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
    # @return [void]
    def snapshot(snapshot_name)
      @_executor.snapshot(rep.unwrap, snapshot_name)
    end
  end
end
