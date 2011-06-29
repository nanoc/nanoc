# encoding: utf-8

class Nanoc::NotificationCenterTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_post
    # Set up notification
    Nanoc::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Post
    @ping_received = false
    Nanoc::NotificationCenter.post :ping_received
    assert(@ping_received)
  end

  def test_remove
    # Set up notification
    Nanoc::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Remove observer
    Nanoc::NotificationCenter.remove :ping_received, :test

    # Post
    @ping_received = false
    Nanoc::NotificationCenter.post :ping_received
    assert(!@ping_received)
  end

end
