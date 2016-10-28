module Nanoc
  class PostCompileItemRepView < ::Nanoc::ItemRepView
    def compiled_content(snapshot: nil)
      if unwrap.binary?
        raise Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem.new(unwrap)
      end

      snapshot_contents = @context.compiler.compiled_content_cache[unwrap]
      snapshot_name = snapshot || (snapshot_contents[:pre] ? :pre : :last)

      if snapshot_contents[snapshot_name]
        snapshot_contents[snapshot_name].string
      else
        raise Nanoc::Int::Errors::NoSuchSnapshot.new(unwrap, snapshot_name)
      end
    end
  end
end
