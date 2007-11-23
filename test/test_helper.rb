require File.dirname(__FILE__) + '/../lib/nanoc.rb'

def with_site_fixture(a_fixture)
  in_dir(['test', 'fixtures', a_fixture]) do
    yield(Nanoc::Site.from_cwd)
  end
end
