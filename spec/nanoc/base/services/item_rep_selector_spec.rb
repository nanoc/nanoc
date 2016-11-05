describe Nanoc::Int::ItemRepSelector do
  let(:selector) { described_class.new(reps_for_selector) }

  let(:item) do
    Nanoc::Int::Item.new('stuff', {}, '/foo.md')
  end

  let(:reps_array) do
    [
      Nanoc::Int::ItemRep.new(item, :a),
      Nanoc::Int::ItemRep.new(item, :b),
      Nanoc::Int::ItemRep.new(item, :c),
      Nanoc::Int::ItemRep.new(item, :d),
      Nanoc::Int::ItemRep.new(item, :e),
    ]
  end

  let(:reps_for_selector) { reps_array }

  let(:names_to_reps) do
    reps_array.each_with_object({}) do |rep, acc|
      acc[rep.name] = rep
    end
  end

  let(:dependencies) { {} }

  let(:result) do
    tentatively_yielded = []
    successfully_yielded = []
    selector.each do |rep|
      tentatively_yielded << rep.name

      dependencies.fetch(rep.name, []).each do |name|
        unless successfully_yielded.include?(name)
          raise Nanoc::Int::Errors::UnmetDependency.new(names_to_reps[name])
        end
      end

      successfully_yielded << rep.name
    end

    [tentatively_yielded, successfully_yielded]
  end

  let(:tentatively_yielded) { result[0] }
  let(:successfully_yielded) { result[1] }

  describe 'yield order' do
    context 'linear dependencies' do
      let(:dependencies) do
        {
          a: [:b],
          b: [:c],
          c: [:d],
          d: [:e],
          e: [],
        }
      end

      example do
        expect(successfully_yielded).to eq [:e, :d, :c, :b, :a]
        expect(tentatively_yielded).to eq [:a, :b, :c, :d, :e, :d, :c, :b, :a]
      end
    end

    context 'no dependencies' do
      let(:dependencies) do
        {}
      end

      example do
        expect(successfully_yielded).to eq [:a, :b, :c, :d, :e]
        expect(tentatively_yielded).to eq [:a, :b, :c, :d, :e]
      end
    end

    context 'star dependencies' do
      let(:dependencies) do
        {
          a: [:b, :c, :d, :e],
        }
      end

      example do
        expect(successfully_yielded).to eq [:b, :c, :d, :e, :a]
        expect(tentatively_yielded).to eq [:a, :b, :c, :d, :e, :a]
      end
    end

    context 'star dependencies; selectively recompiling' do
      let(:reps_for_selector) { reps_array.first(1) }

      let(:dependencies) do
        {
          a: [:b, :c, :d, :e],
        }
      end

      example do
        expect(successfully_yielded).to eq [:b, :c, :d, :e, :a]
        expect(tentatively_yielded).to eq [:a, :b, :a, :c, :a, :d, :a, :e, :a]
      end
    end
  end
end
