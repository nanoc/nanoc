# frozen_string_literal: true

module Nanoc
  module Core
    class CompilationItemRepView < ::Nanoc::Core::BasicItemRepView
      # How long to wait before the requested file appears.
      #
      # This is a bit of a hack -- ideally, Nanoc would know that the file is
      # being generated, and wait the appropriate amount of time.
      FILE_APPEAR_TIMEOUT = 10.0

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

        res = @item_rep.raw_path(snapshot: snapshot)

        unless @item_rep.compiled?
          Fiber.yield(Nanoc::Core::Errors::UnmetDependency.new(@item_rep, snapshot))
        end

        # Wait for file to exist
        if res
          start = Time.now
          sleep 0.05 until File.file?(res) || Time.now - start > FILE_APPEAR_TIMEOUT
          raise Nanoc::Core::Errors::InternalInconsistency, "File did not apear in time: #{res}" unless File.file?(res)
        end

        res
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
        @context.compiled_content_store.compiled_content(rep: _unwrap, snapshot: snapshot)
      end
    end
  end
end
