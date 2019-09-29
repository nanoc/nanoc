# frozen_string_literal: true

describe 'GH-1378', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('content')
    File.write('outside.scss', 'p { color: red; }')
    File.write('content/style.scss', '@import "../outside.scss";')

    File.write('Rules', <<~EOS)
      compile '/*' do
        filter :sass, syntax: :scss
        write ext: 'css'
      end
    EOS
  end

  example do
    expect { Nanoc::OrigCLI.run([]) }
      .to change { File.file?('output/style.css') }
      .from(false)
      .to(true)

    expect(File.read('output/style.css')).to match(/p\s*{\s*color:\s*red;\s*}/)
  end
end
