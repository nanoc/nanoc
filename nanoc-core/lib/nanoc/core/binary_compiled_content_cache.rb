# frozen_string_literal: true

module Nanoc
  module Core
    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # @api private
    class BinaryCompiledContentCache < ::Nanoc::Core::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        super(Nanoc::Core::Store.tmp_path_for(config:, store_name: 'binary_content'), 3)

        @cache = {}
      end

      contract Nanoc::Core::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      # Returns the cached compiled content for the given item representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names, and the values the compiled content at the given snapshot.
      def [](rep)
        item_cache = @cache[rep.item.identifier] || {}

        rep_cache = item_cache[rep.name]
        return nil if rep_cache.nil?

        rep_cache.transform_values do |filename|
          Nanoc::Core::Content.create(filename, binary: true)
        end
      end

      contract Nanoc::Core::ItemRep => C::Bool
      def include?(rep)
        item_cache = @cache[rep.item.identifier] || {}
        item_cache.key?(rep.name)
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::BinaryContent] => C::HashOf[Symbol => Nanoc::Core::Content]
      # Sets the compiled content for the given representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names, and the values the compiled content at the given snapshot.
      def []=(rep, content)
        @cache[rep.item.identifier] ||= {}
        @cache[rep.item.identifier][rep.name] ||= {}
        rep_cache = @cache[rep.item.identifier][rep.name]

        content.each do |snapshot, binary_content|
          # Check
          if Nanoc::Core::ContractsSupport.enabled? && !File.file?(binary_content.filename)
            raise Nanoc::Core::Errors::InternalInconsistency, "Binary content at #{binary_content.filename.inspect} does not exist, but is expected to."
          end

          filename = build_filename(rep, snapshot)
          rep_cache[snapshot] = filename

          # Avoid reassigning the same content if this binary cached content was
          # already used, because it was available and the item wasn’t oudated.
          next if binary_content.filename == filename

          # Copy
          FileUtils.mkdir_p(File.dirname(filename))
          smart_cp(binary_content.filename, filename)
        end
      end

      def prune(items:)
        item_identifiers = Set.new(items.map(&:identifier))

        @cache.each_key do |key|
          # TODO: remove unused item reps
          next if item_identifiers.include?(key)

          @cache.delete(key)
          path = dirname_for_item_identifier(key)
          FileUtils.rm_rf(path)
        end
      end

      def data
        @cache
      end

      def data=(new_data)
        @cache = {}

        new_data.each_pair do |item_identifier, content_per_rep|
          @cache[item_identifier] ||= content_per_rep
        end
      end

      def use_clonefile?
        defined?(Clonefile)
      end

      private

      def dirname
        filename + '_data'
      end

      def string_to_path_component(string)
        string.gsub(/[^a-zA-Z0-9]+/, '_') +
          '-' +
          Digest::SHA1.hexdigest(string)[0..9]
      end

      def dirname_for_item_identifier(item_identifier)
        File.join(
          dirname,
          string_to_path_component(item_identifier.to_s),
        )
      end

      def dirname_for_item_rep(rep)
        File.join(
          dirname_for_item_identifier(rep.item.identifier),
          string_to_path_component(rep.name.to_s),
        )
      end

      def build_filename(rep, snapshot_name)
        File.join(
          dirname_for_item_rep(rep),
          string_to_path_component(snapshot_name.to_s),
        )
      end

      # NOTE: Similar to ItemRepWriter#smart_cp (but without hardlinking)
      def smart_cp(from, to)
        # NOTE: hardlinking is not an option in this case, because hardlinking
        # would make it possible for the content to be (inadvertently)
        # changed outside of Nanoc.

        # Try clonefile
        if use_clonefile?
          FileUtils.rm_f(to)
          begin
            res = Clonefile.always(from, to)
            return if res
          rescue Clonefile::UnsupportedPlatform, Errno::ENOTSUP, Errno::EXDEV, Errno::EINVAL
          end
        end

        # Fall back to old-school copy
        if File.file?(to)
          FileUtils.rm_f(to)
        end
        FileUtils.cp(from, to)
      end
    end
  end
end
