# frozen_string_literal: true

module RecordingStudioPlugins
  class PluginAppearance < ApplicationRecord
    self.table_name = "recording_studio_plugin_appearances"
    self.record_timestamps = false

    RECORDABLE_LABEL = "Plugin look"

    def self.declare_hierarchy!
      recording_studio_recordable label: RECORDABLE_LABEL,
                                  root: false,
                                  allowed_parent_types: RecordingStudioPlugins.configuration.admin_root_types
    end

    declare_hierarchy!

    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: %i[image],
      max_file_count: 1
    )

    validates :plugin_key, presence: true

    before_create { self.created_at ||= Time.current }
  end
end
