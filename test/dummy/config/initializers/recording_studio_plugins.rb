# frozen_string_literal: true

RecordingStudioPlugins.configure do |config|
  # config.mount_path = "/recording_studio_plugins"
  # config.hidden_keys = []
  # config.overrides = {}
  # config.extra_categories = []
  config.enabled_plugins = %i[google_drive dropbox]
  config.admin_root_types = ["AdminRoot"]
  config.admin_root_name = "Admin"
  config.layout = ->(controller:) { "application" if controller.devise_controller? }
end

RecordingStudioPlugins.register_mcp_client(
  :chatgpt,
  setup_url: "https://example.com/how-to-connect-chatgpt",
  owner: "dummy"
)
RecordingStudioPlugins.register_mcp_client(
  :grok_bot,
  setup_url: "https://example.com/how-to-connect-grok-bot",
  owner: "dummy"
)

RecordingStudioGoogleDrive.register_oauth_provider if defined?(RecordingStudioGoogleDrive)
RecordingStudioDropbox.register_oauth_provider if defined?(RecordingStudioDropbox)

unless defined?(RecordingStudioGoogleDrive)
  RecordingStudioOauth.register_outbound_provider(
    key: :google_drive,
    kind: :root,
    authorize_url: "/fake_oauth/authorize",
    token_url: "/fake_oauth/token",
    revoke_url: "/fake_oauth/revoke",
    scopes: ["files.read"],
    client_id: "dummy-google-drive",
    client_secret: "dummy-google-drive-secret",
    pkce: true,
    refresh: true
  )
end

unless defined?(RecordingStudioDropbox)
  RecordingStudioOauth.register_outbound_provider(
    key: :dropbox,
    kind: :root,
    authorize_url: "/fake_oauth/authorize",
    token_url: "/fake_oauth/token",
    revoke_url: "/fake_oauth/revoke",
    scopes: ["files.read"],
    client_id: "dummy-dropbox",
    client_secret: "dummy-dropbox-secret",
    pkce: true,
    refresh: true
  )
end
