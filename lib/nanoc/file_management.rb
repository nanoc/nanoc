require 'fileutils'

class FileManager
  @@stack = []
  
  def self.create_dir(a_name)
    @@stack.push(a_name)
    unless File.directory?(File.join(@@stack))
      puts '     create ' + @@stack.join('/')
      FileUtils.mkdir_p(@@stack.join('/'))
    end
    yield if block_given?
    @@stack.pop
  end
  
  def self.create_file(a_name)
    path = @@stack.empty? ? a_name : @@stack.join('/') + '/' + a_name
    FileManager.create_dir(path.sub(/\/[^\/]+$/, '')) if @@stack.empty?
    puts "     #{File.exist?(a_name) ? 'update' : 'create'} " + path
    if block_given?
      open(path, 'w') { |io| io.write(yield) }
    else
      open(path, 'w') { |io| }
    end
  end
  
end
