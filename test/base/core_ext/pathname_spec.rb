# encoding: utf-8

describe 'Pathname#checksum' do

  it 'should work on empty files' do
    begin
      # Create file
      FileUtils.mkdir_p('tmp')
      File.open('tmp/myfile', 'w') { |io| io.write('') }
      timestamp = Time.at(1234569)
      File.utime(timestamp, timestamp, 'tmp/myfile')

      # Create checksum
      pathname = Pathname.new('tmp/myfile')
      pathname.checksum.must_equal 'a14fb47d88069b81034e5fae12b06ff2b07d6215'
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

  it 'should work on all files' do
    begin
      # Create file
      FileUtils.mkdir_p('tmp')
      File.open('tmp/myfile', 'w') { |io| io.write('abc') }
      timestamp = Time.at(1234569)
      File.utime(timestamp, timestamp, 'tmp/myfile')

      # Create checksum
      pathname = Pathname.new('tmp/myfile')
      pathname.checksum.must_equal '200a2a617bdc0e17908da62667cc1a3ed10ef335'
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

end
