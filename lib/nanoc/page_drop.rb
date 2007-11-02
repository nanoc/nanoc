try_require 'liquid'

module Nanoc

  begin
    class PageDrop < ::Liquid::Drop
      def initialize(page)
        @page = page
      end

      def before_method(name)
        # FIXME add support for file, and make sure builtin stuff works
        name == 'content' ? @page.content : @page.attributes[name.to_sym]
      end
    end
  rescue NameError
  end

end
