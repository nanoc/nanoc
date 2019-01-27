# frozen_string_literal: true

module Nanoc
  module Core
    module Helper37F4A8EAF27F4DB0B4AB61117975D519
      def my_sample
        'sample succeeded!'
      end
    end
  end
end

describe Nanoc::Core::Context do
  let(:context) do
    described_class.new(foo: 'bar', baz: 'quux')
  end

  it 'provides instance variables' do
    expect(eval('@foo', context.get_binding)).to eq('bar')
  end

  it 'provides instance methods' do
    expect(eval('foo', context.get_binding)).to eq('bar')
    expect(context).to respond_to(:asdf)
  end

  it 'returns null for unknown instance variables' do
    expect(eval('@asdf', context.get_binding)).to be_nil
  end

  it 'does not provide missing instance methods' do
    expect { eval('asdf', context.get_binding) }.to raise_error(NameError)
    expect(context).not_to respond_to(:asdf)
  end

  it 'supports #include' do
    eval('include Nanoc::Core::Helper37F4A8EAF27F4DB0B4AB61117975D519', context.get_binding)
    expect(eval('my_sample()', context.get_binding)).to eq('sample succeeded!')
  end

  it 'has correct examples' do
    expect('Nanoc::Core::Context#initialize')
      .to have_correct_yard_examples
      .in_file('nanoc-core/lib/nanoc/core/context.rb')
  end
end
