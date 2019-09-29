# frozen_string_literal: true

describe 'GH-1342', site: true, stdio: true do
  before do
    File.write('Rules', <<~EOS)
      preprocess do
        items.create('<%= "hi!" %>', {}, '/hello.html')
      end

      compile '/*' do
        filter :erb
        write ext: 'html'
      end

      postprocess do
        @items.each(&:compiled_content)
      end
    EOS
  end

  example do
    Nanoc::OrigCLI.run([])
    Nanoc::OrigCLI.run([])
  end
end
