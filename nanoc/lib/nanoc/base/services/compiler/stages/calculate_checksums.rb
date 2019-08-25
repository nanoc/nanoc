# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Stages
        class CalculateChecksums < Nanoc::Core::CompilationStage
          def initialize(items:, layouts:, code_snippets:, config:)
            @items = items
            @layouts = layouts
            @code_snippets = code_snippets
            @config = config
          end

          def run
            checksums = {}

            [@items, @layouts].each do |documents|
              documents.each do |document|
                checksums[[document.reference, :content]] =
                  Nanoc::Core::Checksummer.calc_for_content_of(document)
                checksums[[document.reference, :each_attribute]] =
                  Nanoc::Core::Checksummer.calc_for_each_attribute_of(document)
              end
            end

            [@items, @layouts, @code_snippets].each do |objs|
              objs.each do |obj|
                checksums[obj.reference] = Nanoc::Core::Checksummer.calc(obj)
              end
            end

            checksums[@config.reference] =
              Nanoc::Core::Checksummer.calc(@config)
            checksums[[@config.reference, :each_attribute]] =
              Nanoc::Core::Checksummer.calc_for_each_attribute_of(@config)

            Nanoc::Core::ChecksumCollection.new(checksums)
          end
        end
      end
    end
  end
end
