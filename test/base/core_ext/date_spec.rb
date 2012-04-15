# encoding: utf-8

describe 'Date' do

  it 'should not crash when requesting frozen attributes' do
    # This test will pass without patch on MRI 1.9.x, but on MRI 1.8.x it
    # crashes. (Untested on other Ruby implementations such as Rubinius and
    # JRuby).
    d = Date.today
    d.freeze
    d.year
  end

end

