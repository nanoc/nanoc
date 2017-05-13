# frozen_string_literal: true

require 'helper'

class Nanoc::Deploying::Deployers::FogTest < Nanoc::TestCase
  def test_read_etags_with_local_provider
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'local'
      )

      files = [
        mock('file_a'),
        mock('file_b'),
      ]

      assert_equal({}, fog.send(:read_etags, files))
    end
  end

  def test_read_etags_with_aws_provider
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'aws'
      )

      files = [
        mock('file_a', key: 'key_a', etag: 'etag_a'),
        mock('file_b', key: 'key_b', etag: 'etag_b'),
      ]

      expected = {
        'key_a' => 'etag_a',
        'key_b' => 'etag_b',
      }

      assert_equal(expected, fog.send(:read_etags, files))
    end
  end

  def test_calc_local_etag_with_local_provider
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'local'
      )

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      assert_nil fog.send(:calc_local_etag, file_path)
    end
  end

  def test_calc_local_etag_with_aws_provider
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'aws'
      )

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      assert_equal(
        '598d4c200461b81522a3328565c25f7c',
        fog.send(:calc_local_etag, file_path),
      )
    end
  end

  def test_needs_upload_with_missing_remote_etag
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'aws'
      )

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      key = 'some_key'
      etags = {}

      assert fog.send(:needs_upload?, key, file_path, etags)
    end
  end

  def test_needs_upload_with_different_etags
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'aws'
      )

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      key = 'some_key'
      etags = { key => 'some_etag' }

      assert fog.send(:needs_upload?, key, file_path, etags)
    end
  end

  def test_needs_upload_with_identical_etags
    if_have 'fog' do
      fog = Nanoc::Deploying::Deployers::Fog.new(
        'output/', provider: 'aws'
      )

      file_path = 'blah.tmp'
      File.write(file_path, 'hallo')

      key = 'some_key'
      etags = { key => '598d4c200461b81522a3328565c25f7c' }

      refute fog.send(:needs_upload?, key, file_path, etags)
    end
  end
end
