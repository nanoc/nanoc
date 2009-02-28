module Nanoc

  class CompilerDSL

    def initialize(compiler)
      @compiler = compiler
    end

    def page(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#page requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      @compiler.add_page_compilation_rule(identifier, rep_name, block)
    end

    def asset(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#asset requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      @compiler.add_asset_compilation_rule(identifier, rep_name, block)
    end

    def layout(identifier, &block)
      # Require block
      raise ArgumentError.new("#layout requires a block") unless block_given?

      # Create rule
      @compiler.add_layout_compilation_rule(identifier, block)
    end

  end

end
