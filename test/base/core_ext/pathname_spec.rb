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
      pathname.checksum.must_equal 'oU+0fYgGm4EDTl+uErBv8rB9YhU='
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
      pathname.checksum.must_equal 'IAoqYXvcDheQjaYmZ8waPtEO8zU='
    ensure
      FileUtils.rm_rf('tmp')
    end
  end

end
