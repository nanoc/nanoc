# frozen_string_literal: true

describe 'write nil (skip routing rule)', site: true, stdio: true do
  before do
    File.write('content/foo.md', 'foo')

    File.write('Rules', <<~EOS)
      compile '/foo.*' do
        write '/foo-via-compilation-rule.txt'
        write nil
      end

      route '/foo.*' do
        '/foo-via-routing-rule.txt'
      end
    EOS
  end

  it 'starts off empty' do
    expect(File.file?('output/foo-via-compilation-rule.txt')).not_to be
    expect(File.file?('output/foo-via-routing-rule.txt')).not_to be
  end

  it 'outputs creation of correct file' do
    expect { Nanoc::CLI.run(%w[compile --verbose]) rescue nil }
      .to output(/create.*output\/foo-via-compilation-rule\.txt/).to_stdout
  end

  it 'does not output creation of incorrect file' do
    expect { Nanoc::CLI.run(%w[compile --verbose]) rescue nil }
      .not_to output(/create.*output\/foo-via-routing-rule\.txt/).to_stdout
  end

  it 'creates correct file' do
    expect { Nanoc::CLI.run(%w[compile --verbose --debug]) rescue nil }
      .to change { File.file?('output/foo-via-compilation-rule.txt') }
      .from(false)
      .to(true)
  end

  it 'does not create incorrect file' do
    expect { Nanoc::CLI.run(%w[compile --verbose --debug]) rescue nil }
      .not_to change { File.file?('output/foo-via-routing-rule.txt') }
  end
end
