# frozen_string_literal: true

describe 'GH-1352', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', <<~EOS)
      environments:
        default:
          foo: 'bar'
        xxx:
    EOS
  end

  example do
    expect { Nanoc::CLI.run([]) }.to raise_error(JsonSchema::Error)
  end
end
