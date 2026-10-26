# frozen_string_literal: true

module RecordingStudioPlugins
  module KnownProviders
    TABLE = {
      google_drive: {
        name: "Google Drive",
        description: "Import images and files from Google Drive.",
        category: :storage,
        icon: "cloud",
        position: 10,
        about: "Files stay in Drive until you choose which ones to bring in."
      },
      dropbox: {
        name: "Dropbox",
        description: "Import images and files from Dropbox.",
        category: :storage,
        icon: "archive-box",
        position: 20,
        about: "Files stay in Dropbox until you choose which ones to bring in."
      }
    }.freeze

    module_function

    def fetch(key)
      TABLE[key.to_sym]
    end
  end
end
