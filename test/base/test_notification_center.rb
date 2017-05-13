# frozen_string_literal: true

require 'helper'

class Nanoc::Int::NotificationCenterTest < Nanoc::TestCase
  def test_post
    # Set up notification
    Nanoc::Int::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Post
    @ping_received = false
    Nanoc::Int::NotificationCenter.post :ping_received
    assert(@ping_received)
  end

  def test_remove
    # Set up notification
    Nanoc::Int::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Remove observer
    Nanoc::Int::NotificationCenter.remove :ping_received, :test

    # Post
    @ping_received = false
    Nanoc::Int::NotificationCenter.post :ping_received
    assert(!@ping_received)
  end
end
