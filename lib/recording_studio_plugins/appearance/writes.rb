# frozen_string_literal: true

module RecordingStudioPlugins
  module Appearance
    module_function

    def ensure_recording!(key, actor:)
      recording_for(key).presence || insert_recording!(key, actor: actor)
    end

    def insert_recording!(key, actor:)
      created = create_recording!(key, actor: actor)
      return if created.blank?

      reset_index!
      unwrap_recording(created) || recording_for(key)
    rescue ActiveRecord::RecordNotUnique => e
      retry_unique_plugin_key!(e, key)
    end

    def create_recording!(key, actor:)
      admin = admin_recording
      return if admin.blank? || actor.blank?

      with_actor(actor) { record_appearance!(admin, key, actor) }
    rescue ActiveRecord::RecordNotUnique => e
      retry_unique_plugin_key!(e, key)
    end

    def record_appearance!(admin, key, actor)
      PluginAppearance.transaction(requires_new: true) do
        admin.record(PluginAppearance, actor: actor) do |appearance|
          appearance.plugin_key = key.to_s
        end
      end
    end

    def unwrap_recording(value)
      return value if value.respond_to?(:recordable_type)
      return value.recording if value.respond_to?(:recording)

      nil
    end

    def update_name!(key, name:, actor:)
      recording = ensure_recording!(key, actor: actor)
      return if recording.blank?

      new_name = custom_name(key, name)
      return recording if recording.recordable&.name == new_name

      result = revise_name!(recording, key:, name: new_name, actor:)
      reset_index!
      result
    end

    def revise_name!(recording, key:, name:, actor:)
      previous = recording.recordable
      write_name_snapshot(recording, key, name, actor)
    rescue StandardError
      restore_plugin_key!(previous, key)
      raise
    end

    def write_name_snapshot(recording, key, name, actor)
      admin = recording.root_recording || recording.parent_recording
      with_actor(actor) { revise_appearance!(admin, recording, key, name, actor) }
    end

    def revise_appearance!(admin, recording, key, name, actor)
      PluginAppearance.transaction(requires_new: true) do
        clear_plugin_key!(recording.recordable)
        admin.revise(recording, actor: actor) do |appearance|
          appearance.plugin_key = key.to_s
          appearance.name = name
        end
      end
    end

    def clear_plugin_key!(recordable)
      return if recordable.blank?

      PluginAppearance.where(id: recordable.id).update_all(plugin_key: nil)
    end

    def restore_plugin_key!(recordable, key)
      return if recordable.blank?

      PluginAppearance.where(id: recordable.id, plugin_key: nil).update_all(plugin_key: key.to_s)
    end

    def retry_unique_plugin_key!(err, key)
      names = [err.message, err.cause&.message].compact.join
      raise unless names.include?(UNIQUE_PLUGIN_KEY_INDEX)

      reset_index!
      recording_for(key)
    end

    def custom_name(key, name)
      text = name.to_s.strip.presence
      registered = RecordingStudioPlugins.find(key)&.name
      return if text.blank? || (registered.present? && text == registered)

      text
    end

    def replace_image!(key, io:, filename:, content_type:, actor:)
      recording = ensure_recording!(key, actor: actor)
      return if recording.blank? || io.blank?

      remove_image!(key, actor: actor)
      recording = recording_for(key) || recording
      result = RecordingStudioAttachable::Services::ImportAttachment.call(
        parent_recording: recording,
        io: io,
        filename: filename,
        content_type: content_type,
        actor: actor,
        source: "direct_upload"
      )
      raise result.error if result.failure?

      reset_index!
      result.value
    end
  end
end
