# frozen_string_literal: true

module Nanoc
  module Core
    # Nanoc::Core::CodeSnippet represent a piece of custom code of a Nanoc site.
    #
    # @api private
    class CodeSnippet
      include Nanoc::Core::ContractsSupport

      # A string containing the actual code in this code snippet.
      #
      # @return [String]
      attr_reader :data

      # The filename corresponding to this code snippet.
      #
      # @return [String]
      attr_reader :filename

      contract String, String => C::Any
      # Creates a new code snippet.
      #
      # @param [String] data The raw source code which will be executed before
      #   compilation
      #
      # @param [String] filename The filename corresponding to this code snippet
      def initialize(data, filename)
        @data     = data
        @filename = filename
      end

      contract C::None => nil
      # Loads the code by executing it.
      #
      # @return [void]
      def load
        # rubocop:disable Security/Eval
        eval('def self.use_helper(mod); Nanoc::Core::Context.instance_eval { include mod }; end', TOPLEVEL_BINDING)
        eval(@data, TOPLEVEL_BINDING, @filename)
        # rubocop:enable Security/Eval
        nil
      end

      # Returns an object that can be used for uniquely identifying objects.
      #
      # @return [Object] An unique reference to this object
      def reference
        "code_snippet:#{filename}"
      end

      def inspect
        "<#{self.class} filename=\"#{filename}\">"
      end
    end
  end
end
