class Nanoc::DataSource

  def initialize(site)
    @site = site
  end

  # Attributes

  class << self
    attr_accessor :_name
    attr_accessor :_requirements
  end

  def self.name(name=nil)
    name.nil? ? self._name : self._name = name
  end

  def self.requires(*names)
    self._requirements ||= []
    names.each { |name| self._requirements << name }
  end

  def self.requirements
    self._requirements || []
  end

  # Initialization

  def up
  end

  def down
  end

  def setup
  end

  # Loading data

  def pages
    $stderr.puts 'ERROR: DataSource#pages must be overridden'
    exit(1)
  end

  def page_defaults
    $stderr.puts 'ERROR: DataSource#page_defaults must be overridden'
    exit(1)
  end

  def layouts
    $stderr.puts 'ERROR: DataSource#layouts must be overridden'
    exit(1)
  end

  def templates
    $stderr.puts 'ERROR: DataSource#templates must be overridden'
    exit(1)
  end

  # Creating data

  def create_page(name, template_name)
    $stderr.puts 'ERROR: DataSource#create_page must be overridden'
    exit(1)
  end

  def create_layout(name)
    $stderr.puts 'ERROR: DataSource#create_layout must be overridden'
    exit(1)
  end

  def create_template(name)
    $stderr.puts 'ERROR: DataSource#create_template must be overridden'
    exit(1)
  end

end
