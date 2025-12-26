# frozen_string_literal: true

module Nanoc
  module Core
    class CompilationItemRepView < ::Nanoc::Core::BasicItemRepView
      # @abstract
      def item_view_class
        Nanoc::Core::CompilationItemView
      end

      # Returns the item rep’s raw path. It includes the path to the output
      # directory and the full filename.
      #
      # @param [Symbol] snapshot The snapshot for which the path should be
      #   returned.
      #
      # @return [String] The item rep’s raw path.
      def raw_path(snapshot: :last)
        @context.dependency_tracker.bounce(_unwrap.item, compiled_content: true)

        raw_path = @item_rep.raw_path(snapshot:)

        unless @item_rep.compiled?
          raise Nanoc::Core::Errors::UnmetDependency.new(@item_rep, snapshot)
        end

        # Ensure file exists
        if raw_path && !File.file?(raw_path)
          raise Nanoc::Core::Errors::InternalInconsistency,
                "File `#{raw_path}` expected to exist, but did not."
        end

        raw_path
      end

      # Returns the compiled content.
      #
      # @param [String] snapshot The name of the snapshot from which to
      #   fetch the compiled content. By default, the returned compiled content
      #   will be the content compiled right before the first layout call (if
      #   any).
      #
      # @return [String] The content at the given snapshot.
      def compiled_content(snapshot: nil)
        @context.dependency_tracker.bounce(_unwrap.item, compiled_content: true)
        @context.compiled_content_repo.compiled_content(rep: _unwrap, snapshot:)
      end
    end
  end
end
