module Nanoc3

  # Nanoc3::RuleContext provides a context in which compilation and routing
  # rules can be executed. It provides access to the item representation that
  # is being compiled or routed.
  class RuleContext

    # @param [Nanoc3::ItemRep] rep The item representation for which to create
    #   a new rule context.
    def initialize(rep)
      @rep = rep
    end

    # @return [Nanoc3::ItemRep] The representation that is currently being
    #   processed in this context.
    def rep
      @rep
    end

    # @return [Nanoc3::Item] The item of the representation that is currently
    #   being processed in this context.
    def item
      rep.item
    end

    # @return [Nanoc3::Site] The site of the item representation that is
    #   currently being processed in this context.
    def site
      item.site
    end

    # @return [Hash] The configuration of the site of the item representation
    #   that is currently being processed in this context.
    def config
      site.config
    end

    # @return [Array<Nanoc3::Item>] The items in the site of the item
    #   representation that is currently being processed in this context.
    def items
      site.items
    end

    # @return [Array<Nanoc3::Layout>] The layouts in the site of the item
    #   representation that is currently being processed in this context.
    def layouts
      site.layouts
    end

    # Filters the current representation (calls {Nanoc3::ItemRep#filter} with
    # the given arguments on the rep).
    #
    # @see Nanoc3::ItemRep#filter
    #
    # @param [Symbol] filter_name The name of the filter to run the item
    #   representations' content through
    #
    # @param [Hash] filter_args The filter arguments that should be passed to
    #   the filter's #run method
    #
    # @return [void]
    def filter(filter_name, filter_args={})
      rep.filter(filter_name, filter_args)
    end

    # Layouts the current representation (calls {Nanoc3::ItemRep#layout} with
    # the given arguments on the rep).
    #
    # @see Nanoc3::ItemRep#layout
    #
    # @param [String] layout_identifier The identifier of the layout the ite
    #   should be laid out with
    #
    # @return [void]
    def layout(layout_identifier)
      rep.layout(layout_identifier)
    end

    # Creates a snapshot of the current compiled item content. Calls
    # {Nanoc3::ItemRep#snapshot} with the given arguments on the rep.
    #
    # @see Nanoc3::ItemRep#snapshot
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @return [void]
    def snapshot(snapshot_name)
      rep.snapshot(snapshot_name)
    end

  end

end
