# encoding: utf-8

module Nanoc

  # Provides a context in which compilation and routing rules can be executed.
  # It provides access to the item representation that is being compiled.
  #
  # @api private
  class RuleContext < Context

    # @option params [Nanoc::ItemRep] :rep The item representation that will
    #   be processed in this rule context
    #
    # @option params [Nanoc::Site] :site The site
    #
    # @raise [ArgumentError] if the `:rep` or the `:site` option is
    #   missing
    def initialize(params={})
      rep  = params.fetch(:rep)  { raise ArgumentError, "Required :rep option is missing"  }
      site = params.fetch(:site) { raise ArgumentError, "Required :site option is missing" }

      super({
        :rep      => rep,
        :item_rep => rep,
        :item     => rep.item,
        :site     => site,
        :config   => site.config,
        :items    => site.items,
        :layouts  => site.layouts
      })
    end

    # Filters the current representation (calls {Nanoc::ItemRep#filter} with
    # the given arguments on the rep).
    #
    # @see Nanoc::ItemRep#filter
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

    # Layouts the current representation (calls {Nanoc::ItemRep#layout} with
    # the given arguments on the rep).
    #
    # @see Nanoc::ItemRep#layout
    #
    # @param [String] layout_identifier The identifier of the layout the item
    #   should be laid out with
    #
    # @return [void]
    def layout(layout_identifier)
      rep.layout(layout_identifier)
    end

    # Creates a snapshot of the current compiled item content. Calls
    # {Nanoc::ItemRep#snapshot} with the given arguments on the rep.
    #
    # @see Nanoc::ItemRep#snapshot
    #
    # @param [Symbol] snapshot_name The name of the snapshot to create
    #
    # @return [void]
    def snapshot(snapshot_name)
      rep.snapshot(snapshot_name)
    end

    def write(path, params={})
      rep.write(path, params)
    end

  end

end
