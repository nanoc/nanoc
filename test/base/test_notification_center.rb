# encoding: utf-8

require 'test/helper'

class Nanoc3::NotificationCenterTest < Nanoc3::TestCase

  def test_post
    # Set up notification
    Nanoc3::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Post
    @ping_received = false
    Nanoc3::NotificationCenter.post :ping_received
    assert(@ping_received)
  end

  def test_remove
    # Set up notification
    Nanoc3::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Remove observer
    Nanoc3::NotificationCenter.remove :ping_received, :test

    # Post
    @ping_received = false
    Nanoc3::NotificationCenter.post :ping_received
    assert(!@ping_received)
  end

end
