describe Nanoc::Helpers::Capturing, helper: true do
  describe '#content_for' do
    before do
      ctx.item = ctx.create_item('some content', {}, '/about.md')
      ctx.create_rep(ctx.item, '/about.html')
    end

    describe 'with name + block' do
      let(:_erbout) { 'existing content' }

      context 'only name given' do
        subject { helper.content_for(:foo) { _erbout << 'foo' } }

        it 'stores snapshot content' do
          subject
          expect(ctx.item.reps[:default].unwrap.snapshot_contents[:__capture_foo].string).to eql('foo')
        end
      end

      context 'name and params given' do
        subject { helper.content_for(:foo, params) { _erbout << 'foo' } }
        let(:params) { raise 'overwrite me' }

        context 'no existing behavior specified' do
          let(:params) { {} }

          it 'errors after two times' do
            helper.content_for(:foo, params) { _erbout << 'foo' }
            expect { helper.content_for(:foo, params) { _erbout << 'bar' } }.to raise_error(RuntimeError)
          end
        end

        context 'existing behavior is :overwrite' do
          let(:params) { { existing: :overwrite } }

          it 'overwrites' do
            helper.content_for(:foo, params) { _erbout << 'foo' }
            helper.content_for(:foo, params) { _erbout << 'bar' }
            expect(ctx.item.reps[:default].unwrap.snapshot_contents[:__capture_foo].string).to eql('bar')
          end
        end

        context 'existing behavior is :append' do
          let(:params) { { existing: :append } }

          it 'appends' do
            helper.content_for(:foo, params) { _erbout << 'foo' }
            helper.content_for(:foo, params) { _erbout << 'bar' }
            expect(ctx.item.reps[:default].unwrap.snapshot_contents[:__capture_foo].string).to eql('foobar')
          end
        end

        context 'existing behavior is :error' do
          let(:params) { { existing: :error } }

          it 'errors after two times' do
            helper.content_for(:foo, params) { _erbout << 'foo' }
            expect { helper.content_for(:foo, params) { _erbout << 'bar' } }.to raise_error(RuntimeError)
          end
        end

        context 'existing behavior is :something else' do
          let(:params) { { existing: :donkey } }

          it 'errors' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end
      end
    end

    describe 'with item + name' do
      subject { helper.content_for(item, :foo) }

      let(:_erbout) { 'existing content' }

      context 'requesting for same item' do
        let(:item) { ctx.item }

        context 'nothing captured' do
          it { is_expected.to be_nil }
        end

        context 'something captured' do
          before do
            helper.content_for(:foo) { _erbout << 'I have been captured!' }
          end

          it { is_expected.to eql('I have been captured!') }
        end
      end

      context 'requesting for other item' do
        let(:item) { ctx.items['/other.md'] }

        before do
          item = ctx.create_item('other content', {}, '/other.md')
          ctx.create_rep(item, '/other.html')
        end

        context 'other item is not yet compiled' do
          it 'raises an unmet dependency error' do
            expect(ctx.dependency_tracker).to receive(:bounce).with(item.unwrap, compiled_content: true)
            expect { subject }.to raise_error(FiberError)
          end
        end

        context 'other item is compiled' do
          before do
            item.reps[:default].unwrap.compiled = true
            item.reps[:default].unwrap.snapshot_contents[:__capture_foo] =
              Nanoc::Int::TextualContent.new('other captured foo')
          end

          it 'returns the captured content' do
            expect(ctx.dependency_tracker).to receive(:bounce).with(item.unwrap, compiled_content: true)
            expect(subject).to eql('other captured foo')
          end
        end
      end
    end
  end

  describe '#capture' do
    let(:_erbout) { 'existing content' }

    subject { helper.capture { _erbout << 'new content' } }

    it 'returns the appended content' do
      expect(subject).to eql('new content')
    end

    it 'does not modify _erbout' do
      subject
      expect(_erbout).to eql('existing content')
    end
  end
end
