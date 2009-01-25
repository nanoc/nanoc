module Nanoc

  # Nanoc::PageDefaults represent the default attributes for all pages in the
  # site. If a specific page attribute is requested, but not found, then the
  # page defaults will be queried for this attribute. (If the attribute
  # doesn't even exist in the page defaults, hardcoded defaults will be used.)
  class PageDefaults < Defaults

  end

end
