module Nanoc::Int
  # Stores checksums for objects in order to be able to detect whether a file
  # has changed since the last site compilation.
  #
  # @api private
  class ChecksumStore < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    attr_writer :checksums
    attr_accessor :objects

    c_obj = C::Or[Nanoc::Int::Item, Nanoc::Int::Layout, Nanoc::Int::Configuration, Nanoc::Int::CodeSnippet]

    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site], objects: C::IterOf[c_obj]] => C::Any
    def initialize(site: nil, objects:)
      super(Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'checksums'), 1)

      @objects = objects

      @checksums = {}
    end

    contract c_obj => C::Maybe[String]
    def [](obj)
      @checksums[obj.reference]
    end

    contract c_obj => self
    def add(obj)
      if obj.is_a?(Nanoc::Int::Document)
        @checksums[[obj.reference, :content]] = Nanoc::Int::Checksummer.calc_for_content_of(obj)
        @checksums[[obj.reference, :each_attribute]] = Nanoc::Int::Checksummer.calc_for_each_attribute_of(obj)
      end

      @checksums[obj.reference] = Nanoc::Int::Checksummer.calc(obj)

      self
    end

    contract c_obj => C::Maybe[String]
    def content_checksum_for(obj)
      @checksums[[obj.reference, :content]]
    end

    contract c_obj => C::Maybe[C::HashOf[Symbol, String]]
    def attributes_checksum_for(obj)
      @checksums[[obj.reference, :each_attribute]]
    end

    protected

    def data
      @checksums
    end

    def data=(new_data)
      references = Set.new(@objects.map(&:reference))

      @checksums = {}
      new_data.each_pair do |key, checksum|
        if references.include?(key) || references.include?(key.first)
          @checksums[key] = checksum
        end
      end
    end
  end
end
