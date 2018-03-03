# frozen_string_literal: true

describe 'GH-1323', site: true, stdio: true do
  before do
    File.write('content/stuff.html', 'stuff')

    File.write('lib/stuff.rb', <<~EOS)
      Nanoc::Filter.define(:filter_gh1323) do |content, params = {}|
        nil
      end
    EOS

    File.write('Rules', <<~EOS)
      compile '/**/*' do
        filter :filter_gh1323
      end
    EOS
  end

  example do
    expect { Nanoc::CLI.run(%w[compile]) }
      .to raise_error { |e| e.unwrap.is_a?(Nanoc::Int::Errors::FilterReturnedNil) }
  end
end
