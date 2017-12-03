# frozen_string_literal: true

describe Nanoc::Helpers::Filtering, helper: true do
  describe '#filter' do
    before do
      ctx.create_item('some content', { title: 'Hello!' }, '/about.md')
      ctx.create_rep(ctx.items['/about.md'], '/about.html')

      ctx.item = ctx.items['/about.md']
      ctx.item_rep = ctx.item.reps[:default]
    end

    let(:content) do
      "A<% filter :erb do %><%%= 'X' %><% end %>B"
    end

    subject { ::ERB.new(content).result(helper.get_binding) }

    context 'basic case' do
      it { is_expected.to eql('AXB') }

      it 'notifies' do
        ns = Set.new
        Nanoc::Int::NotificationCenter.on(:filtering_started) { ns << :filtering_started }
        Nanoc::Int::NotificationCenter.on(:filtering_ended)   { ns << :filtering_ended   }

        subject

        expect(ns).to include(:filtering_started)
        expect(ns).to include(:filtering_ended)
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
        expect { subject }.to raise_error(Nanoc::Int::Errors::UnknownFilter)
      end
    end

    context 'with locals' do
      let(:content) do
        "A<% filter :erb, locals: { sheep: 'baah' } do %><%%= @sheep %><% end %>B"
      end

      it { is_expected.to eql('AbaahB') }
    end

    context 'with Haml' do
      let(:content) do
        "%p Foo.\n" \
        "- filter(:erb) do\n" \
        "  <%= 'abc' + 'xyz' %>\n" \
        "%p Bar.\n"
      end

      before do
        require 'haml'
      end

      subject { ::Haml::Engine.new(content).render(helper.get_binding) }

      it { is_expected.to match(%r{^<p>Foo.</p>\s*abcxyz\s*<p>Bar.</p>$}) }
    end
  end
end
