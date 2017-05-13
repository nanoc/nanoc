# frozen_string_literal: true

describe 'GH-767', site: true do
  before do
    File.write('content/donkey.md', 'Compiled content donkey!')

    File.write('Rules', <<EOS)
  compile '/**/*' do
    filter :erb, stuff: item.path
    write '/donkey.html'
  end

  layout '/foo.*', :erb
EOS
  end

  it 'does not expose #path on @item' do
    site = Nanoc::Int::SiteLoader.new.new_from_cwd
    expect { site.compile }.to raise_error(NoMethodError, /undefined method .*path.* for .*Nanoc::ItemWithoutRepsView/)
  end
end
