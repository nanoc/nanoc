# encoding: utf-8

module Nanoc3

  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker

    # TODO outdatedness reasons should be objects with descriptions

    # @option params [Nanoc3::Site] :site (nil) The site this outdatedness
    #   checker belongs to.
    #
    # @options params [Nanoc3::ChecksumStore] :checksum_store (nil) The
    #   checksum store where checksums of items, layouts, … are stored.
    def initialize(params={})
      @site           = params[:site]           if params.has_key?(:site)
      @checksum_store = params[:checksum_store] if params.has_key?(:checksum_store)

      @outdatedness_reasons = {}
    end

    # Checks whether the given object is outdated and therefore needs to be
    # recompiled.
    #
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
    #   those outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      case obj.type
        when :item_rep
          !outdatedness_reason_for_item_rep(obj).nil?
        when :item
          obj.reps.any? { |rep| outdated?(rep) }
        when :layout
          checksum_store.object_modified?(obj)
        else
          raise RuntimeError, "do not know how to check outdatedness of #{obj.inspect}"
      end
    end

    # TODO document
    # TODO generalize for items, layouts, …
    def outdatedness_reason_for_item_rep(rep)
      # Outdated if checksums are missing or different
      return Nanoc3::OutdatednessReasons::NotEnoughData if !checksum_store.checksums_available?(rep.item)
      return Nanoc3::OutdatednessReasons::SourceModified if !checksum_store.checksums_identical?(rep.item)

      # Outdated if compiled file doesn't exist (yet)
      return Nanoc3::OutdatednessReasons::NotWritten if rep.raw_path && !File.file?(rep.raw_path)

      # Outdated if code snippets outdated
      return Nanoc3::OutdatednessReasons::CodeSnippetsModified if @site.code_snippets.any? { |cs| checksum_store.object_modified?(cs) }

      # Outdated if configuration outdated
      return Nanoc3::OutdatednessReasons::ConfigurationModified if checksum_store.object_modified?(@site.config)

      # Outdated if rules outdated
      return Nanoc3::OutdatednessReasons::RulesModified if checksum_store.object_modified?(@site.rules_with_reference)

      # Not outdated
      return nil
    end

  private

    # @return [Nanoc3::ChecksumStore] The checksum store
    def checksum_store
      @checksum_store
    end

  end

end
