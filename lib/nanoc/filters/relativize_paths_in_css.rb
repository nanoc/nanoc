module Nanoc::Filters
  class RelativizePathsInCSS < Nanoc::Filter

    identifier :relativize_paths_in_css

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    def run(content)
      content.gsub(/url\((['"]?)(\/.+?)\1\)/) do
        'url(' + $1 + relative_path_to($2) + $1 + ')'
      end
    end

  end
end
