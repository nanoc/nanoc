require 'fileutils'

class FileManager
  @@stack = []
  
  def self.create_dir(a_name)
    @@stack.push(a_name)
    puts '     create ' + @@stack.join('/')
    FileUtils.mkdir_p(@@stack.join('/'))
    yield if block_given?
    @@stack.pop
  end
  
  def self.create_file(a_name)
    path = @@stack.empty? ? a_name : @@stack.join('/') + '/' + a_name
    puts "     #{File.exist?(a_name) ? 'update' : 'create'} " + path
    if block_given?
      open(path, 'w') { |io| io.write(yield) }
    else
      open(path, 'w') { |io| }
    end
  end
  
end
