# frozen_string_literal: true

describe 'GH-787', site: true, stdio: true do
  before do
    File.write('Rules', <<EOS)
  preprocess do
    @items.create('foo', {}, '/pig.md')
  end

  compile '/**/*' do
    write '/oink.html'
  end

  layout '/foo.*', :erb
EOS
  end

  it 'runs the preprocessor only once' do
    expect { Nanoc::CLI.run(['compile']) }.not_to raise_error
  end
end
