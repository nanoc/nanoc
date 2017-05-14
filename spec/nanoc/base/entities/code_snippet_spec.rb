# frozen_string_literal: true

describe Nanoc::Int::CodeSnippet do
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

      it 'makes helper functions available in contexts' do
        expect { subject }
          .to change { [Nanoc::Int::Context.new({}).respond_to?(:fe345b48e4), Complex.respond_to?(:fe345b48e4)] }
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

      it 'makes helper functions available everywhere' do
        expect { subject }
          .to change { [Nanoc::Int::Context.new({}).respond_to?(:e0f0c30b5e), Complex.respond_to?(:e0f0c30b5e)] }
          .from([false, false])
          .to([true, false])
      end
    end
  end
end
