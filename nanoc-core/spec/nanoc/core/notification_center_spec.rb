# frozen_string_literal: true

shared_examples 'a notification center' do
  it 'receives notification after subscribing' do
    res = false
    subject.on :ping_received, :test do
      res = true
    end

    subject.post(:ping_received).sync
    expect(res).to be
  end

  it 'does not receive notification after unsubscribing' do
    res = false
    subject.on :ping_received, :test do
      res = true
    end

    subject.remove :ping_received, :test

    subject.post(:ping_received).sync
    expect(res).not_to be
  end
end

describe Nanoc::Core::NotificationCenter do
  describe 'class' do
    subject { described_class }

    it_behaves_like 'a notification center'
  end

  describe 'instance' do
    subject { described_class.instance }

    it_behaves_like 'a notification center'
  end
end
