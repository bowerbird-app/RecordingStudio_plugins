# frozen_string_literal: true

RecordingStudioPlugins.configure do |config|
  # config.mount_path = "/recording_studio_plugins"
  # config.hidden_keys = []
  # config.overrides = {}
  # config.extra_categories = []
  config.enabled_plugins = %i[google_drive dropbox]
  config.admin_root_types = ["AdminRoot"]
  config.admin_root_name = "Admin"
  config.layout = lambda do |controller:|
    next "application" if controller.devise_controller?
    next "recording_studio/blank" if controller.controller_path == "recording_studio_plugins/admin/appearances"

    nil
  end
end

RecordingStudioPlugins.register_mcp_client(
  :chatgpt,
  setup_url: "https://chatgpt.com",
  owner: "dummy"
)
RecordingStudioPlugins.register_mcp_client(
  :grok_bot,
  setup_url: "https://grok.com",
  owner: "dummy"
)
