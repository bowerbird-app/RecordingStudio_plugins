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

# Extra workspace plugins so an admin dashboard row exceeds CARD_LIMIT and can show Show more.
# Each exposes a dummy Connect POST so the directory row is not actionless.
module DummyOverflowPlugin
  def self.provider(key)
    Class.new do
      define_singleton_method(:status) do |_context|
        RecordingStudioPlugins::Status.new(
          action_label: "Connect",
          action_url: "/dummy_plugins/#{key}/connect"
        )
      end
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
    provider: DummyOverflowPlugin.provider(key),
    position: position,
    owner: "dummy",
    kind: :root
  )
end
