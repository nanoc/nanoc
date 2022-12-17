# frozen_string_literal: true

describe Nanoc::Helpers::Filtering, helper: true do
  describe '#filter' do
    subject { ERB.new(content).result(helper.get_binding) }

    before do
      ctx.create_item('some content', { title: 'Hello!' }, '/about.md')
      ctx.create_rep(ctx.items['/about.md'], '/about.html')

      ctx.item = ctx.items['/about.md']
      ctx.item_rep = ctx.item.reps[:default]
    end

    let(:content) do
      "A<% filter :erb do %><%%= 'X' %><% end %>B"
    end

    context 'basic case' do
      it { is_expected.to eql('AXB') }

      it 'notifies filtering_started' do
        expect { subject }.to send_notification(:filtering_started, ctx.item_rep._unwrap, :erb)
      end

      it 'notifies filtering_ended' do
        expect { subject }.to send_notification(:filtering_ended, ctx.item_rep._unwrap, :erb)
      end
    end

    context 'with assigns' do
      let(:content) do
        'A<% filter :erb do %><%%= @item[:title] %><% end %>B'
      end

      it { is_expected.to eql('AHello!B') }
    end

    context 'unknonwn filter name' do
      let(:content) do
        'A<% filter :donkey do %>X<% end %>B'
      end

      it 'errors' do
        expect { subject }.to raise_error(Nanoc::Filter::UnknownFilterError)
      end
    end

    context 'with locals' do
      let(:content) do
        "A<% filter :erb, locals: { sheep: 'baah' } do %><%%= @sheep %><% end %>B"
      end

      it { is_expected.to eql('AbaahB') }
    end
  end
end
