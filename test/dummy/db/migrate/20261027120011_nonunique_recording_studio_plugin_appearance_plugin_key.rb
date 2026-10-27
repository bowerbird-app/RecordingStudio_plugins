# frozen_string_literal: true

class NonuniqueRecordingStudioPluginAppearancePluginKey < ActiveRecord::Migration[8.1]
  def change
    return unless index_exists?(:recording_studio_plugin_appearances, :plugin_key)

    remove_index :recording_studio_plugin_appearances, :plugin_key
    add_index :recording_studio_plugin_appearances, :plugin_key
  end
end
