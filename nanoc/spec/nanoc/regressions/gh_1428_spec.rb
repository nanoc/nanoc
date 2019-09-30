# frozen_string_literal: true

describe 'GH-1428', site: true, stdio: true do
  before do
    FileUtils.mkdir_p('layouts')
    File.write('layouts/default.erb', 'layout stuff')

    File.write('Rules', <<~EOS)
      ignore '/*'
      layout '/*', :erb
    EOS
  end

  example do
    Nanoc::CLI.run([])
    Nanoc::CLI.run(['show-data'])
  end
end
