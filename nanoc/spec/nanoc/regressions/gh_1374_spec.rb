# frozen_string_literal: true

describe 'GH-1374', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    File.write('content/test.md', 'hello')

    File.write('Rules', <<~EOS)
      compile '/*' do
        write nil
      end

      passthrough '/*'
    EOS
  end

  example do
    expect { Nanoc::CLI.run([]) }
      .not_to change { File.file?('output/test.md') }
      .from(false)
  end
end
