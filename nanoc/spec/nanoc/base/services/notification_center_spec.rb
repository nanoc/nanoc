# frozen_string_literal: true

describe Nanoc::Int::NotificationCenter do
  it 'receives notification after subscribing' do
    res = false
    Nanoc::Int::NotificationCenter.on :ping_received, :test do
      res = true
    end

    Nanoc::Int::NotificationCenter.post(:ping_received).sync
    expect(res).to be
  end

  it 'does not receive notification after unsubscribing' do
    res = false
    Nanoc::Int::NotificationCenter.on :ping_received, :test do
      res = true
    end

    Nanoc::Int::NotificationCenter.remove :ping_received, :test

    Nanoc::Int::NotificationCenter.post(:ping_received).sync
    expect(res).not_to be
  end
end
