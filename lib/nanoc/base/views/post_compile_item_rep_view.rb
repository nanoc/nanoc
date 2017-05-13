# frozen_string_literal: true

module Nanoc
  class PostCompileItemRepView < ::Nanoc::ItemRepView
    def compiled_content(snapshot: nil)
      snapshot_contents = @context.compilation_context.compiled_content_cache[unwrap]

      snapshot_name = snapshot || (snapshot_contents[:pre] ? :pre : :last)

      unless snapshot_contents[snapshot_name]
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(unwrap, snapshot_name)
      end

      content = snapshot_contents[snapshot_name]
      if content.binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(unwrap)
      end

      content.string
    end

    def raw_path(snapshot: :last)
      @item_rep.raw_path(snapshot: snapshot)
    end
  end
end
