module Nanoc::Int
  # Represents a cache than can be used to store already compiled content,
  # to prevent it from being needlessly recompiled.
  #
  # @api private
  class CompiledContentCache
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[site: C::Maybe[Nanoc::Int::Site], items: C::IterOf[Nanoc::Int::Item]] => C::Any
    def initialize(site: nil, items:)
      @items = items

      filename = Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'cococa')
      FileUtils.mkdir_p(File.dirname(filename))
      @db = Nanoc::Int::DDDB.new(filename)
      @db.open
    end

    def load
      item_identifier_strings = Set.new(@items.map { |i| i.identifier.to_s })

      @db.keys.each do |key|
        identifier_string, _name = *Marshal.load(key)
        unless item_identifier_strings.include?(identifier_string)
          @db.delete(key)
        end
      end

      @db.compact
    end

    def store
      # TODO: compact
      @db.flush
    end

    contract Nanoc::Int::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Int::Content]]
    def [](rep)
      key = Marshal.dump([rep.item.identifier.to_s, rep.name])
      raw_data = @db[key]
      raw_data && Marshal.load(raw_data)
    end

    contract Nanoc::Int::ItemRep, C::HashOf[Symbol => Nanoc::Int::Content] => self
    def []=(rep, content)
      key = Marshal.dump([rep.item.identifier.to_s, rep.name])
      @db[key] = Marshal.dump(content)
      self
    end
  end
end
