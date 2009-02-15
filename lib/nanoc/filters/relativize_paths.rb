module Nanoc::Filters
  class RelativizePaths < Nanoc::Filter

    identifier :relativize_paths

    require 'nanoc/helpers/link_to'
    include Nanoc::Helpers::LinkTo

    # TODO also relativize paths in CSS

    def run(content)
      content.gsub(/(src|href)=(['"]?)(\/.+?)\2([ >])/) do
        $1 + '=' + $2 + relative_path_to($3) + $2 + $4
      end
    end

  end
end
