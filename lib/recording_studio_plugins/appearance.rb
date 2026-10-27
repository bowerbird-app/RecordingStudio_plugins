# frozen_string_literal: true

module RecordingStudioPlugins
  module Appearance
    RECORDABLE_TYPE = "RecordingStudioPlugins::PluginAppearance"

    module_function

    def display_name(definition)
      current_recordable(definition.key)&.name.presence || definition.name
    end

    def image_url(definition)
      file = image_file(definition.key)
      return if file.blank?

      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    rescue StandardError
      nil
    end

    def image_recording(key)
      parent = recording_for(key)
      return if parent.blank? || !parent.respond_to?(:attachments)

      parent.attachments(scope: :direct, per_page: 1).first
    end

    def recording_for(key)
      return unless recordings_ready?

      appearance_recordings.find do |recording|
        recording.recordable&.plugin_key == key.to_s
      end
    end

    def current_recordable(key) = recording_for(key)&.recordable

    def ensure_recording!(key, actor:)
      existing = recording_for(key)
      return existing if existing.present?

      admin = admin_recording
      return if admin.blank? || actor.blank?

      created = with_actor(actor) do
        admin.record(PluginAppearance, actor: actor) do |appearance|
          appearance.plugin_key = key.to_s
        end
      end
      unwrap_recording(created) || recording_for(key)
    end

    def unwrap_recording(value)
      return value if value.is_a?(RecordingStudio::Recording)
      return value.recording if value.respond_to?(:recording)

      nil
    end

    def update_name!(key, name:, actor:)
      recording = ensure_recording!(key, actor: actor)
      return if recording.blank?

      new_name = name.to_s.strip.presence
      return recording if recording.recordable&.name == new_name

      revise_name!(recording, key:, name: new_name, actor:)
    end

    def revise_name!(recording, key:, name:, actor:)
      admin = recording.root_recording || recording.parent_recording
      with_actor(actor) do
        admin.revise(recording, actor: actor) do |appearance|
          appearance.plugin_key = key.to_s
          appearance.name = name
        end
      end
    end

    def remove_image!(key, actor:)
      attachment = image_recording(key)
      return if attachment.blank?

      result = RecordingStudioAttachable::Services::RemoveAttachment.call(
        attachment_recording: attachment,
        actor: actor
      )
      raise result.error if result.failure?
    end

    def admin_recording = RecordingStudioPlugins.configuration.admin_recording_resolver.call

    def appearance_recordings
      admin = admin_recording
      relation = if admin.respond_to?(:recordings_of)
                   admin.recordings_of(PluginAppearance)
                 else
                   RecordingStudio::Recording.where(recordable_type: RECORDABLE_TYPE)
                 end
      if RecordingStudio::Recording.respond_to?(:recording_studio_trashable_kept_sql)
        relation = relation.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
      end
      relation.includes(:recordable)
    end

    def image_file(key)
      recordable = image_recording(key)&.recordable
      return unless recordable.respond_to?(:file)

      file = recordable.file
      file if file.respond_to?(:attached?) && file.attached?
    end

    def recordings_ready?
      return false unless defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?
      return false unless RecordingStudioPlugins.const_defined?(:PluginAppearance)

      PluginAppearance.table_exists?
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid, NameError
      false
    end

    def with_actor(actor)
      previous_actor = Current.actor if defined?(Current)
      Current.actor = actor if defined?(Current)
      yield
    ensure
      Current.actor = previous_actor if defined?(Current)
    end
  end
end
