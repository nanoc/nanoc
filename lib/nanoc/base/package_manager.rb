# Requirements

require 'open-uri'
require 'yaml'

# Classes

module Nanoc
  module PackageManagement

    class Package

      attr_reader :type, :name, :releases

      def initialize(name, type, releases)
        @name     = name
        @type     = type
        @releases = releases.sort { |x, y| x[:version] <=> y[:version] }
      end

      def latest_release
        @releases.last
      end

      def release_for_version(version)
        @releases.find { |r| r[:version] == version }
      end

      def to_s
        "#{type}:#{name} [#{releases.map { |r| r[:version] }.join(', ')}]"
      end

      def to_yaml
        { 'name' => @name, 'type' => @type, 'releases' => @releases }.to_yaml
      end

    end

    class PackageManager

      TYPES = {
        'filters'           => :filter,
        'data sources'      => :data_source,
        'layout processors' => :layout_processor
      }

      DATABASE_URL            = 'http://localhost/~ddfreyne/nanoc-packages/packages.yaml'

      # Managing the database

      def load_database
        return unless @packages.nil?

        puts 'Updating database...'

        # Get database
        packages_yaml = open(DATABASE_URL).read
        package_hashes = YAML.load(packages_yaml)

        # Convert to Packages
        @packages = package_hashes.map do |hash|
          Package.new(
            hash['name'],
            hash['type'].to_sym,
            hash['releases'].map do |release|
              { :version => release['version'], :url => release['url']}
            end
          )
        end
      end

      # Finding packages

      def packages
        # Prepare
        self.load_database

        @packages
      end

      def packages_of_type(type)
        # Prepare
        self.load_database

        @packages.select { |p| p.type == type.to_sym }
      end

      def packages_named(name)
        # Prepare
        self.load_database

        @packages.select { |p| p.name == name }
      end

      def find_packages(params)
        # Prepare
        self.load_database

        packages = @packages

        packages = packages.select { |p| p.type == params[:type].to_sym } unless params[:type].nil?
        packages = packages.select { |p| p.name == params[:name] }        unless params[:name].nil?

        packages
      end

      def find_package(params)
        # Prepare
        self.load_database

        find_packages(params).first
      end

      def package_and_release_with_identifier(identifier)
        # Prepare
        self.load_database

        # Parse identifier
        if identifier =~ /^(\w+):([\w-]+)@([\w\d.-]+)$/ # type:name@version
          type    = $1
          name    = $2
          version = $3
        elsif identifier =~ /^(\w+):([\w-]+)$/ # type:name
          type    = $1
          name    = $2
          version = nil
        elsif identifier =~ /^([\w-]+)@([\w\d.-]+)$/ # name@version
          type    = nil
          name    = $1
          version = $2
        elsif identifier =~ /^([\w-]+)$/ # name
          type    = nil
          name    = $1
          version = nil
        else
          error "Unparseable package identifier: '#{identifier}'"
        end

        # Find package
        package = self.find_package(:type => type, :name => name)
        error "Unknown package: '#{identifier}'" if package.nil?

        # Find release
        release = version.nil? ? package.latest_release : package.release_for_version(version)
        error "Unknown package version: '#{version}'" if release.nil?

        # Return package and version
        [ package, release ]
      end

      # Installing, updating, uninstalling

      def install_package_with_identifier(identifier)
        # Get package and release
        package, release = *package_and_release_with_identifier(identifier)

        # Get filename
        filename = 'lib/packages/' + package.name + '-' + release[:version] + '.rb'

        # Check whether this package is already installed
        error 'This package is already installed.' if File.file?(filename)
        unless Dir['lib/packages/' + package.name + '-*.rb'].empty?
          error 'A different version from this package is already installed.' + 
                'Use \'pkg update [package_name]\' to update the package.'
        end

        # Download package
        source = open(release[:url]).read

        # Save package
        puts 'Installing ' + filename + ' ...'
        FileUtils.mkdir_p('lib/packages')
        File.open(filename, 'w') { |io| io.write(source) }
      end

      def uninstall_package_with_identifier(identifier)
        # Get package and release
        package, release = *package_and_release_with_identifier(identifier)

        # Get filename
        old_filenames = Dir['lib/packages/' + package.name + '-*.rb']

        # Remove old packages
        old_filenames.each do |old_filename|
          puts 'Removing ' + old_filename + ' ...'
          FileUtils.remove_entry_secure(old_filename)
        end
      end

      def update_package_with_identifier(identifier)
        # Get package and release
        package, release = *package_and_release_with_identifier(identifier)

        # Get filename
        filename = 'lib/packages/' + package.name + '-' + release[:version] + '.rb'
        old_filenames = Dir['lib/packages/' + package.name + '-*.rb']

        # Check whether we really are updating
        error 'This package is up to date.' if old_filenames.sort.last == filename

        # Remove old packages
        old_filenames.each do |old_filename|
          puts 'Removing ' + old_filename + ' ...'
          FileUtils.remove_entry_secure(old_filename)
        end

        # Download package
        source = open(release[:url]).read

        # Save package
        puts 'Installing ' + filename + ' ...'
        FileUtils.mkdir_p('lib/packages')
        File.open(filename, 'w') { |io| io.write(source) }
      end

    end

  end
end
