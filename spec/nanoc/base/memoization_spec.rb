describe Nanoc::Int::Memoization do
  class MemoizationSpecSample1
    extend Nanoc::Int::Memoization

    def initialize(value)
      @value = value
    end

    def run(n)
      @value * 10 + n
    end
    memoize :run
  end

  class MemoizationSpecSample2
    extend Nanoc::Int::Memoization

    def initialize(value)
      @value = value
    end

    def run(n)
      @value * 100 + n
    end
    memoize :run
  end

  class MemoizationSpecUpcaser
    extend Nanoc::Int::Memoization

    def run(value)
      value.upcase
    end
    memoize :run
  end

  class MemoizationSpecUpcaserAltSyntax
    extend Nanoc::Int::Memoization

    memoized def run(value)
      value.upcase
    end
  end

  example do
    sample1a = MemoizationSpecSample1.new(10)
    sample1b = MemoizationSpecSample1.new(15)
    sample2a = MemoizationSpecSample2.new(20)
    sample2b = MemoizationSpecSample2.new(25)

    3.times do
      expect(sample1a.run(5)).to eq(10 * 10 + 5)
      expect(sample1b.run(7)).to eq(10 * 15 + 7)
      expect(sample2a.run(5)).to eq(100 * 20 + 5)
      expect(sample2b.run(7)).to eq(100 * 25 + 7)
    end
  end

  it 'supports frozen objects' do
    sample = MemoizationSpecSample1.new(10)
    sample.freeze
    sample.run(5)
  end

  it 'supports memoized def … syntax' do
    upcaser = MemoizationSpecUpcaserAltSyntax.new
    expect(upcaser.run('hi')).to eq('HI')
  end

  it 'does not crash on #inspect' do
    upcaser = MemoizationSpecUpcaser.new
    10_000.times do |i|
      upcaser.run("hello world #{i}")
    end

    GC.start
    GC.start

    upcaser.inspect
  end

  it 'sends notifications' do
    sample = MemoizationSpecSample1.new(10)
    expect { sample.run(5) }.to send_notification(:memoization_miss, 'MemoizationSpecSample1#run')
    expect { sample.run(5) }.to send_notification(:memoization_hit, 'MemoizationSpecSample1#run')
    expect { sample.run(5) }.to send_notification(:memoization_hit, 'MemoizationSpecSample1#run')
  end
end
