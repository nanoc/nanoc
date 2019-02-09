# frozen_string_literal: true

module Nanoc
  module Int
    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # @api private
    class BinaryCompiledContentCache < ::Nanoc::Int::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        super(Nanoc::Int::Store.tmp_path_for(config: config, store_name: 'binary_content'), 1)
      end

      contract Nanoc::Core::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      # Returns the cached compiled content for the given item representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names. and the values the compiled content at the given snapshot.
      def [](rep)
        cached = file_for(rep)
        return nil unless File.directory?(cached)

        Dir[File.join(cached, '*')]
          .select { |e| File.file?(e) }
          .each_with_object({}) do |f, memo|
            snapshot_name = File.basename(f).to_sym

            memo[snapshot_name] = Nanoc::Core::Content.create(f, binary: true)
          end
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::HashOf[Symbol => Nanoc::Core::Content]
      # Sets the compiled content for the given representation.
      #
      # This cached compiled content is a hash where the keys are the snapshot
      # names. and the values the compiled content at the given snapshot.
      def []=(rep, content)
        binaries = rep.snapshot_defs.select(&:binary?).map(&:name)

        content
          .select { |snapshot, _| binaries.include?(snapshot) }
          .each do |snapshot, binary_content|
          cached = file_for(rep, snapshot: snapshot)

          next if File.identical?(binary_content.filename, cached)

          FileUtils.mkdir_p(File.dirname(cached))
          FileUtils.cp(binary_content.filename, cached)
        end
      end

      def prune(items:)
        kept_dirs = Set.new(items.map(&:identifier))
                       .map { |i| File.join(filename, i) }

        extra = Dir["#{filename}/**/*"].select { |e| File.directory?(e) }
                                       .reject { |f| kept_dirs.any? { |k| f.start_with?(k) } }
                                       .reject { |d| Dir["#{d}/*"].select { |e| File.file?(e) }.empty? }

        extra.each { |f| FileUtils.rm_rf(f) }
      end

      def load(*args); end

      def store(*args); end

      private

      def file_for(rep, snapshot: '')
        File.join(filename, rep.item.identifier.to_s, rep.name.to_s, snapshot.to_s)
      end
    end
  end
end
