module Nanoc::Filters
  class RelativizePathsInHTML < Nanoc::Filter

    identifiers :relativize_paths, :relativize_paths_in_html

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    def run(content)
      content.gsub(/(src|href)=(['"]?)(\/.+?)\2([ >])/) do
        $1 + '=' + $2 + relative_path_to($3) + $2 + $4
      end
    end

  end
end
