# frozen_string_literal: true

class CreateRecordingStudioPluginAppearances < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_plugin_appearances, id: :uuid do |t|
      t.string :plugin_key, null: false
      t.string :name
      t.datetime :created_at, null: false
    end

    add_index :recording_studio_plugin_appearances, :plugin_key, unique: true
  end
end
