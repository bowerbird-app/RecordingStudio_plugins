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
    assert defined?(RecordingStudioGoogleDrive)
    assert defined?(RecordingStudioDropbox)

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

  test "google drive and dropbox gems register real authorize urls when credentials are stubbed" do
    previous = nil
    previous = oauth_env_snapshot
    ENV["GOOGLE_DRIVE_CLIENT_ID"] = "stub-google-client"
    ENV["GOOGLE_DRIVE_CLIENT_SECRET"] = "stub-google-secret"
    ENV["DROPBOX_APP_KEY"] = "stub-dropbox-key"
    ENV["DROPBOX_APP_SECRET"] = "stub-dropbox-secret"

    Rails.env = "development"
    RecordingStudioOauth::Outbound.reset_providers!
    load Rails.root.join("config/initializers/recording_studio_google_drive.rb")
    load Rails.root.join("config/initializers/recording_studio_dropbox.rb")

    google = RecordingStudioOauth::Outbound.provider(:google_drive)
    dropbox = RecordingStudioOauth::Outbound.provider(:dropbox)

    assert google.present?
    assert dropbox.present?
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", google.authorize_url
    assert_includes google.authorize_url, "accounts.google.com"
    assert_equal "https://www.dropbox.com/oauth2/authorize", dropbox.authorize_url
    assert_includes dropbox.authorize_url, "dropbox.com"
    assert_nil google.http
    refute_equal FakeDropboxOauth, dropbox.http
    refute_includes google.inspect, "stub-google-secret"
    refute_includes dropbox.inspect, "stub-dropbox-secret"
  ensure
    Rails.env = "test"
    restore_oauth_env!(previous)
    RecordingStudioOauth::Outbound.reset_providers!
    load Rails.root.join("config/initializers/recording_studio_google_drive.rb")
    load Rails.root.join("config/initializers/recording_studio_dropbox.rb")
  end

  private

  def master_key_available?
    ENV["RAILS_MASTER_KEY"].to_s.strip.present? || File.exist?(Rails.root.join("config/master.key"))
  end

  def oauth_env_snapshot
    {
      "GOOGLE_DRIVE_CLIENT_ID" => ENV["GOOGLE_DRIVE_CLIENT_ID"],
      "GOOGLE_DRIVE_CLIENT_SECRET" => ENV["GOOGLE_DRIVE_CLIENT_SECRET"],
      "DROPBOX_APP_KEY" => ENV["DROPBOX_APP_KEY"],
      "DROPBOX_APP_SECRET" => ENV["DROPBOX_APP_SECRET"]
    }
  end

  def restore_oauth_env!(previous)
    return if previous.nil?

    previous.each do |name, value|
      if value.nil?
        ENV.delete(name)
      else
        ENV[name] = value
      end
    end
  end
end
