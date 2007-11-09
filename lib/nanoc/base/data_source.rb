class Nanoc::DataSource

  def initialize(site)
    @site = site
  end

  def up
  end

  def down
  end

  def pages
    $stderr.puts 'ERROR: Nanoc::DataSource#pages must be overridden in subclasses'
    exit(1)
  end

  def layouts
    $stderr.puts 'ERROR: Nanoc::DataSource#layouts must be overridden in subclasses'
    exit(1)
  end

  def templates
    $stderr.puts 'ERROR: Nanoc::DataSource#templates must be overridden in subclasses'
    exit(1)
  end

end
