# frozen_string_literal: true

describe Nanoc::Helpers::Rendering, helper: true do
  describe '#render' do
    subject { helper.instance_eval { render('/partial.erb') } }

    let(:action_sequence_for_layout) do
      [Nanoc::Int::ProcessingActions::Filter.new(:erb, {})]
    end

    let(:layout_view) { ctx.layouts[layout_identifier] }
    let(:layout) { layout_view.unwrap }

    before do
      ctx.create_layout(layout_content, {}, layout_identifier)
      ctx.update_action_sequence(layout, action_sequence_for_layout)
    end

    context 'legacy identifier' do
      let(:layout_identifier) { Nanoc::Identifier.new('/partial/', type: :legacy) }

      context 'cleaned identifier' do
        subject { helper.instance_eval { render('/partial/') } }

        context 'layout without instructions' do
          let(:layout_content) { 'blah' }

          it { is_expected.to eql('blah') }

          it 'tracks proper dependencies' do
            expect(ctx.dependency_tracker).to receive(:enter)
              .with(an_instance_of(Nanoc::Int::LayoutCollection), raw_content: true, attributes: false, compiled_content: false, path: false)
              .ordered
            expect(ctx.dependency_tracker).to receive(:enter)
              .with(layout, raw_content: true, attributes: false, compiled_content: false, path: false)
              .ordered

            subject
          end
        end

        context 'layout with instructions' do
          let(:layout_content) { 'blah <%= @layout.identifier %>' }
          it { is_expected.to eql('blah /partial/') }
        end
      end

      context 'non-cleaned identifier' do
        subject { helper.instance_eval { render('/partial') } }

        context 'layout without instructions' do
          let(:layout_content) { 'blah' }
          it { is_expected.to eql('blah') }
        end

        context 'layout with instructions' do
          let(:layout_content) { 'blah <%= @layout.identifier %>' }
          it { is_expected.to eql('blah /partial/') }
        end
      end
    end

    context 'full-style identifier' do
      let(:layout_identifier) { Nanoc::Identifier.new('/partial.erb') }

      context 'layout without instructions' do
        let(:layout_content) { 'blah' }
        it { is_expected.to eql('blah') }
      end

      context 'layout with instructions' do
        let(:layout_content) { 'blah <%= @layout.identifier %>' }
        it { is_expected.to eql('blah /partial.erb') }
      end

      context 'printing wrapped layout class' do
        let(:layout_content) { 'blah <%= @layout.class %>' }
        it { is_expected.to eql('blah Nanoc::LayoutView') }
      end

      context 'printing unwrapped layout class' do
        let(:layout_content) { 'blah <%= @layout.unwrap.class %>' }
        it { is_expected.to eql('blah Nanoc::Int::Layout') }
      end

      context 'unknown layout' do
        subject { helper.instance_eval { render('/unknown.erb') } }

        let(:layout_content) { 'blah' }

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::UnknownLayout)
        end
      end

      context 'layout with unknown filter' do
        let(:action_sequence_for_layout) do
          [Nanoc::Int::ProcessingActions::Filter.new(:donkey, {})]
        end

        let(:layout_content) { 'blah' }

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::UnknownFilter)
        end
      end

      context 'layout without filter' do
        let(:action_sequence_for_layout) do
          [Nanoc::Int::ProcessingActions::Filter.new(nil, {})]
        end

        let(:layout_content) { 'blah' }

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::CannotDetermineFilter)
        end
      end

      context 'with block' do
        subject do
          helper.instance_eval do
            render('/partial.erb') { _erbout << 'extra content' }
          end
        end

        before do
          ctx.erbout << '[erbout-before]'
        end

        let(:layout_content) { '[partial-before]<%= yield %>[partial-after]' }

        it 'returns an empty string' do
          expect(subject).to eql('')
        end

        it 'modifies erbout' do
          subject
          expect(ctx.erbout).to eql('[erbout-before][partial-before]extra content[partial-after]')
        end
      end
    end
  end
end
