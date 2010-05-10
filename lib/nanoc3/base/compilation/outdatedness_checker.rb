# encoding: utf-8

module Nanoc3

  # Responsible for determining whether an item or a layout is outdated.
  #
  # @api private
  class OutdatednessChecker

    # TODO outdatedness reasons should be objects with descriptions

    # TODO document
    def initialize(params={})
      @site           = params[:site]           if params.has_key?(:site)
      @checksum_store = params[:checksum_store] if params.has_key?(:checksum_store)

      @outdatedness_reasons = {}
    end

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
    def outdatedness_message_for_reason(reason)
      @reason_to_message_mapping ||= {
        :not_enough_data => 'Not enough data is present to correctly determine whether the item is outdated.',
        :not_written => 'This item representation has not yet been written to the output directory (but it does have a path).',
        :source_modified => 'The source file of this item has been modified since the last time this item representation was compiled.',
        :layouts_outdated => 'The source of one or more layouts has been modified since the last time this item representation was compiled.',
        :code_outdated => 'The code snippets in the `lib/` directory have been modified since the last time this item representation was compiled.',
        :config_outdated => 'The site configuration has been modified since the last time this item representation was compiled.',
        :rules_outdated => 'The rules file has been modified since the last time this item representation was compiled.',
      }

      @reason_to_message_mapping[reason]
    end

    # TODO document
    def outdatedness_reason_for_item_rep(rep)
      # Outdated if checksums are missing or different
      return :not_enough_data if !checksum_store.checksums_available?(rep.item)
      return :source_modified if !checksum_store.checksums_identical?(rep.item)

      # Outdated if compiled file doesn't exist (yet)
      return :not_written if rep.raw_path && !File.file?(rep.raw_path)

      # Outdated if code snippets outdated
      return :code_outdated if @site.code_snippets.any? { |cs| checksum_store.object_modified?(cs) }

      # Outdated if configuration outdated
      return :config_outdated if checksum_store.object_modified?(@site.config)

      # Outdated if rules outdated
      return :rules_outdated  if checksum_store.object_modified?(@site.rules_with_reference)

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
