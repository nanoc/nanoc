# encoding: utf-8

describe 'Pathname#checksum' do

  it 'should work on empty files' do
    begin
      FileUtils.mkdir_p('tmp')
      File.open('tmp/myfile', 'w') { |io| io.write('') }
      pathname = Pathname.new('tmp/myfile')
      pathname.checksum.must_equal 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

  it 'should work on all files' do
    begin
      FileUtils.mkdir_p('tmp')
      File.open('tmp/myfile', 'w') { |io| io.write('abc') }
      pathname = Pathname.new('tmp/myfile')
      pathname.checksum.must_equal 'a9993e364706816aba3e25717850c26c9cd0d89d'
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

end
