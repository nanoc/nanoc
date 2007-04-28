require 'fileutils'

module FileManagement
  def self.create_dir(a_name)
    return if File.exist?(a_name)
    
    puts '     create ' + a_name
    
    FileUtils.mkdir_p(a_name)
  end

  def self.create_file(a_name)
    puts "     #{File.exist?(a_name) ? 'update' : 'create'} " + a_name

    self.create_dir(a_name.sub(/\/[^\/]+$/, ''))
    open(a_name, 'w') { |io| yield io }
  end
end

#####

$dirs = []

def create_dir(a_name)
  $dirs.push(a_name)
  
  FileManagement.create_dir($dirs.join('/'))
  
  yield if block_given?
  
  $dirs.pop
end

def create_file(a_name)
  if block_given?
    FileManagement.create_file($dirs.join('/') + '/' + a_name) { |io| io.write(yield) }
  else
    FileManagement.create_file($dirs.join('/') + '/' + a_name) { |io| }
  end
end
