# frozen_string_literal: true

describe Nanoc::Helpers::Capturing, helper: true do
  describe '#content_for' do
    before do
      ctx.create_item('some content', {}, '/about.md')
      ctx.create_rep(ctx.items['/about.md'], '/about.html')
      ctx.item = ctx.items['/about.md']
    end

    describe 'setting content' do
      let(:_erbout) { String.new('existing content') }

      let(:params) { raise 'overwrite me' }

      let(:contents_enumerator) { %w[foo bar].to_enum }

      shared_examples 'setting content' do
        context 'only name given' do
          subject { subject_proc_without_params.call }

          it 'stores snapshot content' do
            subject
            expect(ctx.snapshot_repo.get(ctx.item.reps[:default].unwrap, :__capture_foo).string).to eql('foo')
          end
        end

        context 'name and params given' do
          subject { subject_proc_with_params.call }
          let(:params) { raise 'overwrite me' }

          context 'no existing behavior specified' do
            let(:params) { {} }

            it 'errors after two times' do
              subject_proc_with_params.call
              expect { subject_proc_with_params.call }.to raise_error(RuntimeError)
            end
          end

          context 'existing behavior is :overwrite' do
            let(:params) { { existing: :overwrite } }

            it 'overwrites' do
              subject_proc_with_params.call
              subject_proc_with_params.call
              expect(ctx.snapshot_repo.get(ctx.item.reps[:default].unwrap, :__capture_foo).string).to eql('bar')
            end
          end

          context 'existing behavior is :append' do
            let(:params) { { existing: :append } }

            it 'appends' do
              subject_proc_with_params.call
              subject_proc_with_params.call
              expect(ctx.snapshot_repo.get(ctx.item.reps[:default].unwrap, :__capture_foo).string).to eql('foobar')
            end
          end

          context 'existing behavior is :error' do
            let(:params) { { existing: :error } }

            it 'errors after two times' do
              subject_proc_with_params.call
              expect { subject_proc_with_params.call }.to raise_error(RuntimeError)
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

      context 'symbol name + block' do
        let(:subject_proc_without_params) do
          -> { helper.content_for(:foo) { _erbout << contents_enumerator.next } }
        end

        let(:subject_proc_with_params) do
          -> { helper.content_for(:foo, params) { _erbout << contents_enumerator.next } }
        end

        include_examples 'setting content'
      end

      context 'string name + block' do
        let(:subject_proc_without_params) do
          -> { helper.content_for('foo') { _erbout << contents_enumerator.next } }
        end

        let(:subject_proc_with_params) do
          -> { helper.content_for('foo', params) { _erbout << contents_enumerator.next } }
        end

        include_examples 'setting content'
      end

      context 'symbol name + string' do
        let(:subject_proc_without_params) do
          -> { helper.content_for(:foo, contents_enumerator.next) }
        end

        let(:subject_proc_with_params) do
          -> { helper.content_for(:foo, params, contents_enumerator.next) }
        end

        include_examples 'setting content'
      end

      context 'string name + string' do
        let(:subject_proc_without_params) do
          -> { helper.content_for('foo', contents_enumerator.next) }
        end

        let(:subject_proc_with_params) do
          -> { helper.content_for('foo', params, contents_enumerator.next) }
        end

        include_examples 'setting content'
      end
    end

    describe 'with item + name' do
      subject { helper.content_for(item, :foo) }

      let(:_erbout) { String.new('existing content') }

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
          ctx.create_item('other content', {}, '/other.md')
          ctx.create_rep(ctx.items['/other.md'], '/other.html')
        end

        context 'other item is not yet compiled' do
          it 'raises an unmet dependency error' do
            expect(ctx.dependency_tracker).to receive(:bounce).with(item.unwrap, compiled_content: true)
            expect { subject }.to raise_error(FiberError)
          end

          it 're-runs when fiber is resumed' do
            expect(ctx.dependency_tracker).to receive(:bounce).with(item.unwrap, compiled_content: true).twice

            fiber = Fiber.new { subject }
            expect(fiber.resume).to be_a(Nanoc::Int::Errors::UnmetDependency)

            item.reps[:default].unwrap.compiled = true
            ctx.snapshot_repo.set(
              item.reps[:default].unwrap,
              :__capture_foo,
              Nanoc::Int::TextualContent.new('content after compilation'),
            )
            expect(fiber.resume).to eql('content after compilation')
          end
        end

        context 'other item is compiled' do
          before do
            item.reps[:default].unwrap.compiled = true
            ctx.snapshot_repo.set(
              item.reps[:default].unwrap,
              :__capture_foo,
              Nanoc::Int::TextualContent.new('other captured foo'),
            )
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
    context 'with string' do
      let(:_erbout) { String.new('existing content') }

      subject { helper.capture { _erbout << 'new content' } }

      it 'returns the appended content' do
        expect(subject).to eql('new content')
      end

      it 'does not modify _erbout' do
        expect { subject }.not_to change { _erbout }
      end
    end

    context 'with array' do
      let(:_erbout) { ['existing content'] }

      shared_examples 'returns properly joined output' do
        subject { helper.capture { _erbout << %w[new _ content] } }

        it 'returns the appended content, joined' do
          expect(subject).to eql('new_content')
        end

        it 'does not modify _erbout' do
          expect { subject }.not_to change { _erbout.join('') }
        end
      end

      context 'default output field separator' do
        include_examples 'returns properly joined output'
      end

      context 'output field separator set to ,' do
        around do |ex|
          orig_output_field_separator = $OUTPUT_FIELD_SEPARATOR
          $OUTPUT_FIELD_SEPARATOR = ','
          ex.run
          $OUTPUT_FIELD_SEPARATOR = orig_output_field_separator
        end

        include_examples 'returns properly joined output'
      end

      context 'output field separator set to nothing' do
        around do |ex|
          orig_output_field_separator = $OUTPUT_FIELD_SEPARATOR
          $OUTPUT_FIELD_SEPARATOR = String.new
          ex.run
          $OUTPUT_FIELD_SEPARATOR = orig_output_field_separator
        end

        include_examples 'returns properly joined output'
      end
    end
  end
end
