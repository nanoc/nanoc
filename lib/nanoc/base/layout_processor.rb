module Nanoc

  # Nanoc::LayoutProcessor is responsible for layouting pages. It is the
  # (abstract) superclass for all layout processors. Subclasses should
  # override the +run+ method.
  class LayoutProcessor < Filter

    class << self

      attr_accessor :extensions # :nodoc:

      # Sets or returns the extensions for this layout processor.
      # 
      # When given a list of extension symbols, sets the extensions for
      # this layout processor. When given nothing, returns an array of
      # extension symbols.
      def extensions(*exts)
        @extensions = [] unless instance_variables.include?('@extensions')
        exts.empty? ? @extensions : @extensions = exts
      end

      # Sets or returns the extension for this layout processor.
      # 
      # When given an extension symbols, sets the extension for this layout
      # processor. When given nothing, returns the extension.
      def extension(ext=nil)
        @extensions = [] unless instance_variables.include?('@extensions')
        ext.nil? ? @extensions.first : extensions(ext)
      end

    end

  end

end
