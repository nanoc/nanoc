require 'helper'

class Nanoc::Routers::DefaultTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_web_path_normal
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          {},
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/', site.router.web_path_for(page))
      end
    end
  end

  def test_web_path_with_custom_path
    # Custom paths aren't handled by the router, so make sure they really aren't!
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          { :custom_path => '/quack/zomg.html' },
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/', site.router.web_path_for(page))
      end
    end
  end

  def test_web_path_with_custom_path
    # Custom paths aren't handled by the router, so make sure they really aren't!
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          { :filename => 'asdf' },
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/', site.router.web_path_for(page))
      end
    end
  end

  def test_web_path_with_custom_path
    # Custom paths aren't handled by the router, so make sure they really aren't!
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          { :extension => 'xyz' },
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/', site.router.web_path_for(page))
      end
    end
  end

  def test_disk_path_normal
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          {},
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/index.html', site.router.disk_path_for(page))
      end
    end
  end

  def test_disk_path_with_custom_path
    # Custom paths aren't handled by the router, so make sure they really aren't!
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          { :custom_path => '/quack/zomg.html' },
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/index.html', site.router.disk_path_for(page))
      end
    end
  end

  def test_disk_path_with_custom_filename
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          { :filename => 'default' },
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/default.html', site.router.disk_path_for(page))
      end
    end
  end

  def test_disk_path_with_custom_extension
    in_dir %w{ tmp } do
      # Create
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data
        
        # Create page
        page = Nanoc::Page.new(
          "Hello, I am a cool page!",
          { :extension => 'htm' },
          '/foo/'
        )
        page.site = site

        # Check path
        assert_equal('/foo/index.htm', site.router.disk_path_for(page))
      end
    end
  end

end
