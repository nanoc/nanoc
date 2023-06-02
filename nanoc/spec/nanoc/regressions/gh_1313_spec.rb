# frozen_string_literal: true

describe 'GH-1313', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', <<~CONFIG)
      output_dir: build/bin/web/bin
      prune:
        auto_prune: true
        exclude:
          - bin
    CONFIG

    FileUtils.mkdir_p('build/bin/web/bin')
    File.write('build/bin/web/bin/should-be-pruned', 'asdf')
  end

  example do
    expect { Nanoc::CLI.run(%w[compile]) }
      .to change { File.file?('build/bin/web/bin/should-be-pruned') }
      .from(true)
      .to(false)
  end
end
