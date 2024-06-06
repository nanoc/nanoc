# frozen_string_literal: true

module Nanoc
  module Core
    class PostCompileItemRepView < ::Nanoc::Core::BasicItemRepView
      def item_view_class
        Nanoc::Core::PostCompileItemView
      end

      def compiled_content(snapshot: nil)
        compilation_context = @context.compilation_context
        snapshot_contents = compilation_context.compiled_content_cache[_unwrap] || {}

        snapshot_name = snapshot || (snapshot_contents[:pre] ? :pre : :last)

        unless snapshot_contents[snapshot_name]
          raise Nanoc::Core::Errors::NoSuchSnapshot.new(_unwrap, snapshot_name)
        end

        content = snapshot_contents[snapshot_name]
        if content.binary?
          raise Nanoc::Core::Errors::CannotGetCompiledContentOfBinaryItem.new(_unwrap)
        end

        content.string
      end

      def raw_path(snapshot: :last)
        @item_rep.raw_path(snapshot:)
      end
    end
  end
end
