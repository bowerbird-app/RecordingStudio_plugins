# frozen_string_literal: true

RecordingStudioPlugins.configure do |config|
  # config.mount_path = "/recording_studio_plugins"
  # config.hidden_keys = []
  # config.overrides = {}
  # config.extra_categories = []
  config.enabled_plugins = %i[google_drive dropbox]
end

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

wordpress = Class.new do
  def self.status(_context)
    RecordingStudioPlugins::Status.new(
      state: :attention,
      message: "The WordPress connection needs another look before a press kit can publish.",
      action_label: "Check connection",
      action_url: "/recording_studio_plugins/wordpress"
    )
  end

  def self.about(_context)
    "Publish a press kit to a WordPress site."
  end
end

grokbot = Class.new do
  def self.status(_context)
    RecordingStudioPlugins::Status.new(
      action_label: "Install",
      action_url: "/recording_studio_plugins/grokbot"
    )
  end

  def self.setup_instructions(_context)
    "Install Grokbot, then pick the press kit it should read."
  end

  def self.usage_instructions(_context)
    "Ask Grokbot about the kit once the install finishes."
  end

  def self.documentation_url(_context)
    "https://example.com/grokbot"
  end
end

website_embed = Class.new do
  def self.about(_context)
    "Place a press kit on a page you already have."
  end

  def self.setup_instructions(_context)
    "Copy the embed and paste it where the kit should appear."
  end

  def self.usage_instructions(_context)
    "Visitors see the kit on the page. You keep editing it here."
  end
end

RecordingStudioPlugins.register(
  :wordpress,
  name: "WordPress",
  description: "Publish a press kit to a WordPress site.",
  category: :websites,
  icon: "globe-alt",
  provider: wordpress,
  position: 30,
  owner: "dummy"
)

RecordingStudioPlugins.register(
  :grokbot,
  name: "Grokbot",
  description: "Let Grokbot answer questions about a press kit.",
  category: :ai_agents,
  icon: "sparkles",
  provider: grokbot,
  position: 40,
  owner: "dummy"
)

RecordingStudioPlugins.register(
  :website_embed,
  name: "Website embed",
  description: "Embed a press kit on a website.",
  category: :websites,
  icon: "code-bracket",
  provider: website_embed,
  position: 50,
  owner: "dummy"
)
