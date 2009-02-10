module Nanoc

  class CompilerDSL

    def initialize(compiler)
      @compiler = compiler
    end

    def page(path, params={}, &block)
      # Require block
      raise ArgumentError.new("#page requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      @compiler.add_page_rule(path, rep_name, block)
    end

    def asset(path, params={}, &block)
      # Require block
      raise ArgumentError.new("#asset requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      @compiler.add_asset_rule(path, rep_name, block)
    end

    def layout(path, &block)
      # Require block
      raise ArgumentError.new("#layout requires a block") unless block_given?

      # Create rule
      @compiler.add_layout_rule(path, block)
    end

  end

end
