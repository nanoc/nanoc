module Nanoc
  class PostCompileItemRepView < ::Nanoc::ItemRepView
    def compiled_content(snapshot: nil)
      # TODO: Change to use cached content
      unwrap.compiled_content(snapshot: snapshot)
    end
  end
end
