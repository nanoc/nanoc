# frozen_string_literal: true

module Nanoc::Int
  class ChecksumCollection
    include Nanoc::Core::ContractsSupport

    c_obj = C::Or[Nanoc::Core::Item, Nanoc::Core::Layout, Nanoc::Core::Configuration, Nanoc::Int::CodeSnippet]

    def initialize(checksums)
      @checksums = checksums
    end

    contract c_obj => C::Maybe[String]
    def checksum_for(obj)
      @checksums[obj.reference]
    end

    contract c_obj => C::Maybe[String]
    def content_checksum_for(obj)
      @checksums[[obj.reference, :content]]
    end

    contract c_obj => C::Maybe[C::HashOf[Symbol, String]]
    def attributes_checksum_for(obj)
      @checksums[[obj.reference, :each_attribute]]
    end

    def to_h
      @checksums
    end
  end
end
