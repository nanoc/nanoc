# frozen_string_literal: true

describe Nanoc::Int::NotificationCenter do
  it 'receives notification after subscribing' do
    ping_received = false
    Nanoc::Int::NotificationCenter.on :ping_received, :test do
      ping_received = true
    end

    Nanoc::Int::NotificationCenter.post :ping_received
    expect(ping_received).to be
  end

  it 'does not receive notification after unsubscribing' do
    ping_received = false
    Nanoc::Int::NotificationCenter.on :ping_received, :test do
      ping_received = true
    end

    Nanoc::Int::NotificationCenter.remove :ping_received, :test

    Nanoc::Int::NotificationCenter.post :ping_received
    expect(ping_received).not_to be
  end
end
