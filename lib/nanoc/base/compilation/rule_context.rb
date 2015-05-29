module Nanoc::Int
  # Provides a context in which compilation and routing rules can be executed.
  # It provides access to the item representation that is being compiled or
  # routed.
  #
  # The following variables will be available in this rules context:
  #
  # * `rep`     ({Nanoc::Int::ItemRep})         - The current item rep
  # * `item`    ({Nanoc::Int::Item})            - The current item
  # * `site`    ({Nanoc::Int::Site})            - The site
  # * `config`  ({Hash})                    - The site configuration
  # * `items`   ({Array}<{Nanoc::Int::Item}>)   - A list of all items
  # * `layouts` ({Array}<{Nanoc::Int::Layout}>) - A list of all layouts
  #
  # @api private
  class RuleContext < Nanoc::Int::Context
    # @option params [Nanoc::Int::ItemRep] :rep The item representation that will
    #   be processed in this rule context
    #
    # @option params [Nanoc::Int::Compiler] :compiler The compiler that is being
    #   used to compile the site
    #
    # @raise [ArgumentError] if the `:rep` or the `:compiler` option is
    #   missing
    def initialize(params = {})
      rep = params.fetch(:rep) do
        raise ArgumentError, 'Required :rep option is missing'
      end
      compiler = params.fetch(:compiler) do
        raise ArgumentError, 'Required :compiler option is missing'
      end

      super({
        rep: rep,
        item_rep: rep,
        item: rep.item,
        site: compiler.site,
        config: compiler.site.config,
        items: compiler.site.items,
        layouts: compiler.site.layouts
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
      rep.filter(filter_name, filter_args)
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
    def layout(layout_identifier)
      rep.layout(layout_identifier)
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
      rep.snapshot(snapshot_name)
    end
  end
end
