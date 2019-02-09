# frozen_string_literal: true

module Nanoc
  class PostCompileItemRepView < ::Nanoc::BasicItemRepView
    def item_view_class
      Nanoc::PostCompileItemView
    end

    def compiled_content(snapshot: nil)
      compilation_context = @context.compilation_context
      snapshot_contents = compilation_context.compiled_content_cache[_unwrap] || {}

      snapshot_name = snapshot || (snapshot_contents[:pre] ? :pre : :last)

      unless snapshot_contents[snapshot_name]
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(_unwrap, snapshot_name)
      end

      content = snapshot_contents[snapshot_name]
      if content.binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(_unwrap)
      end

      content.string
    end

    def raw_path(snapshot: :last)
      @item_rep.raw_path(snapshot: snapshot)
    end
  end
end
