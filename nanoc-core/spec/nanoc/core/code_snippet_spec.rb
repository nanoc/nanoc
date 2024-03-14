# frozen_string_literal: true

describe Nanoc::Core::CodeSnippet do
  subject(:code_snippet) { described_class.new(data, 'lib/foo.rb') }

  describe '#load' do
    subject { code_snippet.load }

    describe 'calling #include' do
      let(:data) do
        <<~EOS
          module CodeSnippetSpecHelper1
            def fe345b48e4
              "fe345b48e4"
            end
          end

          include CodeSnippetSpecHelper1
        EOS
      end

      it 'makes helper functions available everywhere' do
        expect { subject }
          .to change { [Nanoc::Core::Context.new({}).respond_to?(:fe345b48e4), Complex.respond_to?(:fe345b48e4)] }
          .from([false, false])
          .to([true, true])
      end
    end

    describe 'calling #use_helper' do
      let(:data) do
        <<~EOS
          module CodeSnippetSpecHelper2
            def e0f0c30b5e
              "e0f0c30b5e"
            end
          end

          use_helper CodeSnippetSpecHelper2
        EOS
      end

      it 'makes helper functions available in helpers only' do
        expect { subject }
          .to change { [Nanoc::Core::Context.new({}).respond_to?(:e0f0c30b5e), Complex.respond_to?(:e0f0c30b5e)] }
          .from([false, false])
          .to([true, false])
      end
    end

    it 'defines at top level' do
      @foo = 'meow'

      code_snippet = described_class.new("@foo = 'woof'", 'dog.rb')
      code_snippet.load

      expect(@foo).to eq('meow')
    end

    describe 'calling twice' do
      subject do
        2.times { code_snippet.load }
      end

      let(:data) { 'def v5yqq2zmfcjr; "ok"; end' }

      it 'does not write warnings to stdout' do
        expect { subject }.not_to output(/warning: method redefined; discarding old use_helper/).to_stdout
      end

      it 'does not write warnings to stderr' do
        expect { subject }.not_to output(/warning: method redefined; discarding old use_helper/).to_stderr
      end
    end
  end
end
