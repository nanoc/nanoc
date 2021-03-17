# frozen_string_literal: true

describe 'meta', chdir: false do
  # rubocop:disable RSpec/ExampleLength
  it 'has the same license for all projects' do
    Dir.chdir('..') do
      root_license = File.read('LICENSE').sub(/20\d\d/, '20xx')

      projects = %w[nanoc guard-nanoc] + Dir['nanoc-*']
      projects.each do |project|
        project_license = File.read(File.join(project, 'LICENSE')).sub(/20\d\d/, '20xx')
        expect(project_license).to eq(root_license), "expected license for #{project} to be same as root license"
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
