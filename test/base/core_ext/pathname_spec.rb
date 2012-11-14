# encoding: utf-8

describe 'Pathname#checksum' do

  it 'should work on empty files' do
    begin
      # Create file
      FileUtils.mkdir_p('tmp')
      File.open('tmp/myfile', 'w') { |io| io.write('') }
      now = Time.now
      File.utime(now, now, 'tmp/myfile')

      # Create checksum
      pathname = Pathname.new('tmp/myfile')
      pathname.checksum.must_equal '0-' + now.to_s
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

  it 'should work on all files' do
    begin
      # Create file
      FileUtils.mkdir_p('tmp')
      File.open('tmp/myfile', 'w') { |io| io.write('abc') }
      now = Time.now
      File.utime(now, now, 'tmp/myfile')

      # Create checksum
      pathname = Pathname.new('tmp/myfile')
      pathname.checksum.must_equal '3-' + now.to_s
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

end
