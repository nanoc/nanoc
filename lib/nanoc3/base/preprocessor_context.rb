module Nanoc3

  # Nanoc3::PreprocessorContext provides a context in which preprocessing code
  # can be executed. It provides access to the site and its configuration,
  # items and layouts.
  class PreprocessorContext

    # @param [Nanoc3::Site] site The site to create a preprocessor context
    #   for. Items, layouts, … will be fetched from this site.
    def initialize(site)
      @site = site
    end

    # @return [Nanoc3::Site] The site for which the preprocessor code is being
    #   executed.
    def site
      @site
    end

    # @return [Hash] The configuration of the site for which the preprocessor
    #   code is being
    # executed.
    def config
      site.config
    end

    # @return [Array<Nanoc3::Item>] The items in the site for which the
    #   preprocessor code is being executed.
    def items
      site.items
    end

    # @return [Array<Nanoc3::Layout>] The layouts in the site for which the
    #   preprocessor code is being executed.
    def layouts
      site.layouts
    end

  end

end
