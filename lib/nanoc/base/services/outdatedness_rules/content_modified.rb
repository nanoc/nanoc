module Nanoc::Int::OutdatednessRules
  class ContentModified < Nanoc::Int::OutdatednessRule
    affects_props :raw_content, :compiled_content

    def apply(obj, outdatedness_checker)
      obj = obj.item if obj.is_a?(Nanoc::Int::ItemRep)

      ch_old = outdatedness_checker.checksum_store.content_checksum_for(obj)
      ch_new = Nanoc::Int::Checksummer.calc_for_content_of(obj)
      if ch_old != ch_new
        Nanoc::Int::OutdatednessReasons::ContentModified
      end
    end
  end
end
