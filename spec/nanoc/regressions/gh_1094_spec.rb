# frozen_string_literal: true

describe 'GH-1094', site: true, stdio: true do
  before do
    File.write('content/a.dat', 'foo')
    File.write('content/index.html', '<%= @items["/*.dat"].compiled_content %>')

    File.write('Rules', <<EOS)
  compile '/**/*.html' do
    filter :erb
    write item.identifier.to_s
  end

  passthrough '/**/*.dat'
EOS
  end

  it 'raises CannotGetCompiledContentOfBinaryItem twice' do
    2.times do
      expect { Nanoc::CLI.run(%w[compile]) }
        .to raise_wrapped_error(an_instance_of(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem))
    end
  end
end
