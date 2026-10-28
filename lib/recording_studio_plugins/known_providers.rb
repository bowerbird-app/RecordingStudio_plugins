# frozen_string_literal: true

module RecordingStudioPlugins
  module KnownProviders
    TABLE = {
      google_drive: {
        name: "Google Drive",
        description: "Import images and files from Google Drive.",
        category: :storage,
        icon: "cloud",
        position: 10
      },
      dropbox: {
        name: "Dropbox",
        description: "Import images and files from Dropbox.",
        category: :storage,
        icon: "archive-box",
        position: 20
      },
      chatgpt: {
        name: "ChatGPT",
        description: "Talk to this workspace from ChatGPT.",
        category: :ai_agents,
        icon: "chat-bubble-left-right",
        position: 1
      },
      grok_bot: {
        name: "Grok Bot",
        description: "Talk to this workspace from Grok Bot.",
        category: :ai_agents,
        icon: "sparkles",
        position: 2
      }
    }.freeze

    module_function

    def fetch(key)
      TABLE[key.to_sym]
    end
  end
end
