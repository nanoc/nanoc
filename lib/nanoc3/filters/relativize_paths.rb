# encoding: utf-8

module Nanoc3::Filters
  class RelativizePaths < Nanoc3::Filter

    require 'nanoc3/helpers/link_to'
    include Nanoc3::Helpers::LinkTo

    def run(content, params={})
      # Set assigns so helper function can be used
      @item_rep = assigns[:item_rep] if @item_rep.nil?

      # Filter
      case params[:type]
      when :html
        content.gsub(/(<[^>]+\s+(src|href))=(['"]?)(\/.*?)\3([ >])/) do
          $1 + '=' + $3 + relative_path_to($4) + $3 + $5
        end
      when :css
        content.gsub(/url\((['"]?)(\/.*?)\1\)/) do
          'url(' + $1 + relative_path_to($2) + $1 + ')'
        end
      else
        raise RuntimeError.new(
          "The relativize_paths needs to know the type of content to " +
          "process. Pass :type => :html for HTML or :type => :css for CSS."
        )
      end
    end

  end
end
