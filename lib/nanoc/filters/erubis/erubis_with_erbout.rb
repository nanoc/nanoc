# encoding: utf-8

module Nanoc::Filters
  class Erubis

    # The same as `::Erubis::Eruby` but adds `_erbout` as an alias for the
    # `_buf` variable, making it compatible with nanoc’s helpers that rely
    # on `_erbout`, such as {Nanoc::Helpers::Capturing}.
    class ErubisWithErbout < ::Erubis::Eruby
      include ::Erubis::ErboutEnhancer
    end

  end
end
