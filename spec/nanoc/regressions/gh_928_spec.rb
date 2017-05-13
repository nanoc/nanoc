# frozen_string_literal: true

describe 'GH-928', site: true, stdio: true do
  example do
    expect { Nanoc::CLI.run(%w[check --list]) }.to output(%r{^  css$}).to_stdout
  end
end
