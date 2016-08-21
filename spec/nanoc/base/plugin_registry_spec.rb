describe Nanoc::Int::PluginRegistry do
  describe '.identifier(s)' do
    let(:identifier) { :ce79f6b8ddb22233e9aaf7d8f011689492acf02f }

    context 'direct subclass' do
      example do
        klass =
          Class.new(Nanoc::Filter) do
            identifier :plugin_registry_spec
          end

        expect(klass.identifier).to eql(:plugin_registry_spec)
      end
    end

    context 'indirect subclass' do
      example do
        superclass = Class.new(Nanoc::Filter)

        klass =
          Class.new(superclass) do
            identifier :plugin_registry_spec
          end

        expect(klass.identifier).to eql(:plugin_registry_spec)
      end
    end
  end
end
