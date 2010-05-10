# encoding: utf-8

module Nanoc3

  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker

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
    #   whose outdatedness should be checked.
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      !outdatedness_reason_for(obj).nil?
    end

    # Calculates the reason why the given object is outdated.
    #
    # @param [Nanoc3::Item, Nanoc3::ItemRep, Nanoc3::Layout] obj The object
    #   whose outdatedness reason should be calculated.
    #
    # @return [Nanoc3::OutdatednessReason::Generic, nil] The reason why the
    #   given object is outdated, or nil if the object is not outdated.
    def outdatedness_reason_for(obj)
      case obj.type
        when :item_rep
          # Outdated if checksums are missing or different
          return Nanoc3::OutdatednessReasons::NotEnoughData if !checksum_store.checksums_available?(obj.item)
          return Nanoc3::OutdatednessReasons::SourceModified if !checksum_store.checksums_identical?(obj.item)

          # Outdated if compiled file doesn't exist (yet)
          return Nanoc3::OutdatednessReasons::NotWritten if obj.raw_path && !File.file?(obj.raw_path)

          # Outdated if code snippets outdated
          return Nanoc3::OutdatednessReasons::CodeSnippetsModified if @site.code_snippets.any? do |cs|
            checksum_store.object_modified?(cs)
          end

          # Outdated if configuration outdated
          return Nanoc3::OutdatednessReasons::ConfigurationModified if checksum_store.object_modified?(@site.config)

          # Outdated if rules outdated
          return Nanoc3::OutdatednessReasons::RulesModified if checksum_store.object_modified?(@site.rules_with_reference)

          # Not outdated
          return nil
        when :item
          obj.reps.find { |rep| outdatedness_reason_for(rep) }
        when :layout
          # Outdated if checksums are missing or different
          return Nanoc3::OutdatednessReasons::NotEnoughData if !checksum_store.checksums_available?(obj)
          return Nanoc3::OutdatednessReasons::SourceModified if !checksum_store.checksums_identical?(obj)

          # Not outdated
          return nil
        else
          raise RuntimeError, "do not know how to check outdatedness of #{obj.inspect}"
      end
    end

  private

    # @return [Nanoc3::ChecksumStore] The checksum store
    def checksum_store
      @checksum_store
    end

  end

end
