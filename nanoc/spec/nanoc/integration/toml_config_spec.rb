# frozen_string_literal: true

describe 'TOML configuration', site: true, stdio: true do
  example do
    File.write('content/foo.md', '<%= @config[:animal] %>')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        filter :erb
        write '/foo.html'
      end
    EOS

    FileUtils.rm_f('nanoc.yaml')
    File.write('nanoc.toml', <<~EOS)
      animal = "donkey"
    EOS

    Nanoc::Core::Feature.enable(Nanoc::Core::Feature::TOML) do
      Nanoc::CLI.run(%w[compile])
    end

    expect(File.read('output/foo.html')).to eq('donkey')
  end
end
