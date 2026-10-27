# frozen_string_literal: true

require "test_helper"

class CredentialsTest < ActiveSupport::TestCase
  test "dummy credentials expose shared keys when the master key is available" do
    skip "Set RAILS_MASTER_KEY or test/dummy/config/master.key to the shared dummy key" unless master_key_available?

    credentials = Rails.application.credentials
    assert credentials.secret_key_base.present?
    assert_equal "dev_placeholder", credentials.dig(:gem_template, :api_key)
    assert_equal "dev_placeholder", credentials.dig(:smtp, :user_name)
    assert_equal "dev_placeholder", credentials.dig(:smtp, :password)
    assert_equal "dev_placeholder", credentials.dig(:aws, :access_key_id)
    assert_equal "dev_placeholder", credentials.dig(:aws, :secret_access_key)
  end

  test "dummy google drive and dropbox fall back to fake oauth clients in test" do
    google = RecordingStudioOauth::Outbound.provider(:google_drive)
    dropbox = RecordingStudioOauth::Outbound.provider(:dropbox)

    assert_equal FakeOauth::CLIENT_ID, google.client_id
    assert_equal FakeOauth, google.http
    assert_equal "/fake_oauth/authorize", google.authorize_url
    assert_equal FakeDropboxOauth::CLIENT_ID, dropbox.client_id
    assert_equal FakeDropboxOauth, dropbox.http
    assert_equal "/fake_oauth/authorize", dropbox.authorize_url
    refute_includes google.inspect, google.client_secret
    refute_includes dropbox.inspect, dropbox.client_secret
  end

  private

  def master_key_available?
    ENV["RAILS_MASTER_KEY"].to_s.strip.present? || File.exist?(Rails.root.join("config/master.key"))
  end
end
