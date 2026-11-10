# frozen_string_literal: true

RecordingStudioPlugins.configure do |config|
  # config.mount_path = "/recording_studio_plugins"
  if ENV["DASHBOARD_EMPTY"] == "1"
    config.hidden_keys = %i[google_drive dropbox chatgpt grok_bot calendar notes linear]
  end
  # config.overrides = {}
  # config.extra_categories = []
  config.enabled_plugins = %i[google_drive dropbox]
  config.admin_root_types = [ "AdminRoot" ]
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

# Extra workspace plugin so an admin dashboard row exceeds CARD_LIMIT and can show Show more.
module DummyOverflowPlugin
  module Provider
    def self.status(_context)
      RecordingStudioPlugins::Status.new
    end
  end
end

{
  calendar: 30,
  notes: 40,
  linear: 50
}.each do |key, position|
  RecordingStudioPlugins.register(
    key,
    name: key.to_s.capitalize,
    description: "Dummy workspace plugin used to overflow the dashboard card row.",
    category: :storage,
    icon: "puzzle-piece",
    provider: DummyOverflowPlugin::Provider,
    position: position,
    owner: "dummy",
    kind: :root
  )
end
