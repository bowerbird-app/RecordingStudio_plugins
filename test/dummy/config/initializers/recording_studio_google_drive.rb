# frozen_string_literal: true

require Rails.root.join("app/models/fake_oauth")

rails_creds = begin
  Rails.application.credentials
rescue ActiveSupport::EncryptedFile::MissingKeyError, Errno::ENOENT, ArgumentError
  nil
end
nested = rails_creds&.dig(:attachable, :google_drive).presence || rails_creds&.dig(:google_drive).presence || {}
creds = {
  client_id: nested[:client_id].presence || ENV["GOOGLE_DRIVE_CLIENT_ID"].presence,
  client_secret: nested[:client_secret].presence || ENV["GOOGLE_DRIVE_CLIENT_SECRET"].presence
}
real_google = creds[:client_id].present? && creds[:client_secret].present? && !Rails.env.test?

if defined?(RecordingStudioGoogleDrive)
  RecordingStudioGoogleDrive.configure do |config|
    if real_google
      config.authorize_url = "https://accounts.google.com/o/oauth2/v2/auth"
      config.token_url = "https://oauth2.googleapis.com/token"
      config.revoke_url = "https://oauth2.googleapis.com/revoke"
      config.client_id = creds[:client_id]
      config.client_secret = creds[:client_secret]
      config.http = nil
    else
      config.authorize_url = "/fake_oauth/authorize"
      config.token_url = "/fake_oauth/token"
      config.revoke_url = "/fake_oauth/revoke"
      config.client_id = FakeOauth::CLIENT_ID
      config.client_secret = FakeOauth::CLIENT_SECRET
      config.http = FakeOauth
    end
  end
  RecordingStudioGoogleDrive.register_oauth_provider
elsif real_google
  RecordingStudioOauth.register_outbound_provider(
    key: :google_drive,
    kind: :root,
    authorize_url: "https://accounts.google.com/o/oauth2/v2/auth",
    token_url: "https://oauth2.googleapis.com/token",
    revoke_url: "https://oauth2.googleapis.com/revoke",
    scopes: [ "https://www.googleapis.com/auth/drive" ],
    client_id: creds[:client_id],
    client_secret: creds[:client_secret],
    pkce: true,
    refresh: true
  )
else
  RecordingStudioOauth.register_outbound_provider(
    key: :google_drive,
    kind: :root,
    authorize_url: "/fake_oauth/authorize",
    token_url: "/fake_oauth/token",
    revoke_url: "/fake_oauth/revoke",
    scopes: [ FakeOauth::SCOPE ],
    client_id: FakeOauth::CLIENT_ID,
    client_secret: FakeOauth::CLIENT_SECRET,
    pkce: true,
    refresh: true,
    http: FakeOauth
  )
end
