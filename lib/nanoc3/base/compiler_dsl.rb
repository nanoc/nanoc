module Nanoc3

  class CompilerDSL

    def initialize(compiler)
      @compiler = compiler
    end

    def item(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#item requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      @compiler.add_item_compilation_rule(identifier, rep_name, block)
    end

    def layout(params={})
      # Get layout identifier and filter name
      identifier  = params.keys[0]
      filter_name = params.values[0]

      # Create rule
      @compiler.add_layout_compilation_rule(identifier, filter_name)
    end

  end

end
