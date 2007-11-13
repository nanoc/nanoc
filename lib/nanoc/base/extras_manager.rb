module Nanoc
  class ExtrasManager

    def self.data_source_named(name)
      ObjectSpace.each_object(Class) do |klass|
        return klass if klass < Nanoc::DataSource and klass.identifiers.include?(name.to_sym)
      end
      nil
    end

    def self.filter_named(name)
      ObjectSpace.each_object(Class) do |klass|
        return klass if klass < Nanoc::Filter and klass.identifiers.include?(name.to_sym)
      end
      nil
    end

    def self.layout_processor_for_extension(ext)
      ObjectSpace.each_object(Class) do |klass|
        return klass if klass < Nanoc::LayoutProcessor and klass.extensions.include?(ext)
      end
      nil
    end

  end
end
