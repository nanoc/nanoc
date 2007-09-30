try_require 'liquid'

module Nanoc

  begin
    class PageDrop < ::Liquid::Drop
      def initialize(page)
        @page = page
      end

      def before_method(name)
        name == 'content' ? @page.content : @page.attributes[name.to_sym]
      end
    end
  rescue NameError
  end

end
