require 'fileutils'

module FileManagement
  def self.create_dir(a_name, params={})
    # Extract options
    option_recursive = (params[:recursive] == true)

    unless File.exist?(a_name)
      # Log
      puts '     create ' + a_name

      # Create directory
      if option_recursive
        FileUtils.mkdir_p(a_name)
      else
        FileUtils.mkdir(a_name)
      end
    end
  end

  def self.create_file(a_name, params={})
    # Require a block
    if not block_given?
      puts 'error: no block given'
      return
    end

    # Extract options
    option_create_dir = (params[:create_dir] == true)
    option_recursive  = (params[:recursive] == true)

    # Create directory if requested and possible
    if option_create_dir and a_name =~ /\/[^\/]/
      self.create_dir(a_name.sub(/\/[^\/]+$/, ''), :recursive => option_recursive)
    end

    # Log
    if File.exist?(a_name)
      puts '     update ' + a_name
    else
      puts '     create ' + a_name
    end

    # Create file
    open(a_name, 'w') do |io|
      yield io
    end
  end

  def self.delete(a_name, params={})
    # Extract options
    option_recursive = (params[:recursive] == true)

    # Log
    puts '     delete ' + a_name

    # Delete
    if option_recursive
      FileUtils.rm_rf(a_name, :secure => true)
    else
      FileUtils.rm_f(a_name)
    end
  end
end
