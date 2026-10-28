# frozen_string_literal: true

RecordingStudioPlugins.configure do |config|
  # config.mount_path = "/recording_studio_plugins"
  # config.hidden_keys = []
  # config.overrides = {}
  # config.extra_categories = []
  # config.enabled_plugins = %i[google_drive dropbox]
  # config.admin_root_types = ["AdminRoot"]
  # config.admin_root_name = "Admin"
  # config.actor_label = ->(person) { person&.name.presence || person&.email.presence || "User" }
  # config.layout = ->(controller:) { "application" if controller.devise_controller? }
end

# RecordingStudioPlugins.register_mcp_client(:chatgpt, setup_url: "https://chatgpt.com")
# RecordingStudioPlugins.register_mcp_client(:grok_bot, setup_url: "https://grok.com")
