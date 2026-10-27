# frozen_string_literal: true

require "active_support/current_attributes"

module RecordingStudioPlugins
  module Appearance
    RECORDABLE_TYPE = "RecordingStudioPlugins::PluginAppearance"

    class IndexState < ActiveSupport::CurrentAttributes
      attribute :index
    end

    module_function

    def ensure_recording!(key, actor:)
      existing = recording_for(key)
      return existing if existing.present?

      created = create_recording!(key, actor: actor)
      return if created.blank?

      reset_index!
      unwrap_recording(created) || recording_for(key)
    end

    def display_name(definition)
      current_recordable(definition.key)&.name.presence || definition.name
    end

    def image_url(definition)
      file = image_file(definition.key)
      return if file.blank?

      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    end

    def image_recording(key)
      request_index.image_recording(key)
    end

    def recording_for(key)
      request_index.recording_for(key)
    end

    def current_recordable(key) = recording_for(key)&.recordable

    def configured?
      admin_recording.present?
    end

    def create_recording!(key, actor:)
      admin = admin_recording
      return if admin.blank? || actor.blank?

      with_actor(actor) do
        admin.record(PluginAppearance, actor: actor) do |appearance|
          appearance.plugin_key = key.to_s
        end
      end
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

      result = revise_name!(recording, key:, name: new_name, actor:)
      reset_index!
      result
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

      reset_index!
    end

    def admin_recording = RecordingStudioPlugins.configuration.admin_recording_resolver.call

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
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      false
    end

    def with_actor(actor)
      previous_actor = Current.actor if defined?(Current)
      Current.actor = actor if defined?(Current)
      yield
    ensure
      Current.actor = previous_actor if defined?(Current)
    end

    def request_index
      IndexState.index ||= Index.new
    end

    def reset_index!
      IndexState.index = nil
    end

    class Index
      def recording_for(key)
        recordings_by_key[key.to_s]
      end

      def image_recording(key)
        image_recordings_by_key[key.to_s]
      end

      def recordings_by_key
        @recordings_by_key ||= load_recordings_by_key
      end

      def image_recordings_by_key
        @image_recordings_by_key ||= load_image_recordings_by_key
      end

      private

      def load_recordings_by_key
        relation = appearance_relation
        return {} if relation.nil?

        kept(relation).includes(:recordable).each_with_object({}) do |recording, map|
          plugin_key = recording.recordable&.plugin_key
          next if plugin_key.blank?

          map[plugin_key] = recording
        end
      end

      def appearance_relation
        return unless Appearance.recordings_ready?

        admin = Appearance.admin_recording
        return if admin.blank?

        if admin.respond_to?(:recordings_of)
          admin.recordings_of(PluginAppearance)
        else
          RecordingStudio::Recording.where(recordable_type: RECORDABLE_TYPE, parent_recording_id: admin.id)
        end
      end

      def load_image_recordings_by_key
        recordings = recordings_by_key
        attachments_by_parent = attachment_recordings_by_parent(recordings.values.map(&:id))
        recordings.each_with_object({}) do |(plugin_key, recording), map|
          map[plugin_key] = attachments_by_parent[recording.id]&.first
        end
      end

      def attachment_recordings_by_parent(parent_ids)
        return {} if parent_ids.empty? || !defined?(RecordingStudioAttachable::Attachment)

        relation = RecordingStudio::Recording.where(
          parent_recording_id: parent_ids,
          recordable_type: RecordingStudioAttachable::Attachment.name
        )
        kept(relation).includes(:recordable).group_by(&:parent_recording_id)
      end

      def kept(relation)
        if RecordingStudio::Recording.respond_to?(:recording_studio_trashable_kept_sql)
          relation.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
        else
          relation
        end
      end
    end
  end
end
