# frozen_string_literal: true

describe 'GH-804', site: true, stdio: true do
  before do
    File.write('content/item.md', 'Stuff!')
    File.write('Rules', <<EOS)
  compile '/**/*' do
    filter :erb if item[:dynamic]
    write item.identifier.without_ext + '.html'
  end
EOS

    File.write('Checks', <<~EOS)
      check :donkey do
        self.add_issue('Not enough donkeys')
        self.add_issue('Too many cats', subject: '/catlady.md')
      end
EOS
  end

  it 'does not crash' do
    expect { Nanoc::CLI.run(%w[check donkey]) }.to(
      raise_error(Nanoc::Int::Errors::GenericTrivial, 'One or more checks failed').and(
        output(/Issues found!\n  \(global\):\n    \[ (\e\[31m)?ERROR(\e\[0m)? \] donkey - Not enough donkeys\n  \/catlady.md:\n    \[ (\e\[31m)?ERROR(\e\[0m)? \] donkey - Too many cats\n/).to_stdout,
      ),
    )
  end
end
