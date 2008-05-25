require 'helper'

class Nanoc::Routers::DefaultTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_paths_for
    in_dir %w{ tmp } do
      create_site('site')

      in_dir %w{ site } do
        # Create site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))
        site.load_data

        # Create page with normal path
        foo_page = Nanoc::Page.new(
          "Hello, I am Foo!",
          { },
          '/foo/'
        )
        foo_page.site = site

        # Create page with custom path
        bar_page = Nanoc::Page.new(
          "Hello, I am Bar!",
          { :custom_path => '/quack/zomg.html' },
          '/bar/'
        )
        bar_page.site = site

        # Check normal page paths
        assert_equal('/foo/',             site.router.web_path_for(foo_page))
        assert_equal('/foo/index.html',   site.router.disk_path_for(foo_page))

        # Check custom page paths
        assert_equal('/quack/zomg.html',  site.router.web_path_for(bar_page))
        assert_equal('/quack/zomg.html',  site.router.disk_path_for(bar_page))
      end

    end
  end

end
