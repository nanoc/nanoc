# frozen_string_literal: true

RSpec.describe Guard::Nanoc do
  around do |example|
    Dir.mktmpdir('nanoc-test') do |dir|
      __nanoc_core_chdir(dir) do
        Nanoc::CLI.run(%w[create-site foo])
        __nanoc_core_chdir('foo') do
          example.run
        end
      end
    end
  end

  it 'loads the command properly' do
    expect { Nanoc::CLI.run(%w[live]) }.to raise_error(/No Guardfile found, please create one/)
  end
end
