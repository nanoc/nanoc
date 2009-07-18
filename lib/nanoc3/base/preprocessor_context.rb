module Nanoc3

  # Nanoc3::PreprocessorContext provides a context in which preprocessing code
  # can be executed. It provides access to the site and its configuration,
  # items and layouts.
  class PreprocessorContext

    # Creates a new preprocessor context for the given site.
    def initialize(site)
      @site = site
    end

    # The site for which the preprocessor code is being executed.
    def site
      @site
    end

    # The configuration of the site for which the preprocessor code is being
    # executed.
    def config
      site.config
    end

    # The items in the site for which the preprocessor code is being executed.
    def items
      site.items
    end

    # The layouts in the site for which the preprocessor code is being
    # executed.
    def layouts
      site.layouts
    end

  end

end
