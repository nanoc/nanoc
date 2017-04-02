require 'helper'

class Nanoc::Extra::PiperTest < Nanoc::TestCase
  def test_basic
    stdout = StringIO.new
    stderr = StringIO.new

    cmd = %w[ls -l]

    File.open('foo.txt', 'w') { |io| io.write('hi') }
    File.open('bar.txt', 'w') { |io| io.write('ho') }

    piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
    piper.run(cmd, nil)

    assert_match(/foo\.txt/, stdout.string)
    assert_match(/bar\.txt/, stdout.string)
    assert stderr.string.empty?
  end

  def test_stdin
    stdout = StringIO.new
    stderr = StringIO.new

    input = 'Hello World!'
    cmd = %w[cat]

    piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
    piper.run(cmd, input)

    assert_equal(input, stdout.string)
    assert_equal('', stderr.string)
  end

  def test_no_such_command
    stdout = StringIO.new
    stderr = StringIO.new

    cmd = %w[cat kafhawilgoiwaejagoualjdsfilofiewaguihaifeowuiga]

    piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)
    assert_raises(Nanoc::Extra::Piper::Error) do
      piper.run(cmd, nil)
    end
  end
end
