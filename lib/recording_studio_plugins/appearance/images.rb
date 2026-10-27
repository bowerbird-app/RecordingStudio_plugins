# frozen_string_literal: true

module RecordingStudioPlugins
  module Appearance
    module_function

    def replace_image!(key, file:, actor:)
      recording = ensure_recording!(key, actor: actor)
      return if recording.blank? || file.blank?

      import_replaced_image!(key, recording, file:, actor:)
    end

    def import_replaced_image!(key, recording, file:, actor:)
      remove_image!(key, actor: actor)
      result = import_attachment!(recording_for(key) || recording, file:, actor:)
      raise result.error if result.failure?

      reset_index!
      result.value
    end

    def import_attachment!(recording, file:, actor:)
      RecordingStudioAttachable::Services::ImportAttachment.call(
        parent_recording: recording,
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
        actor: actor,
        source: "direct_upload"
      )
    end
  end
end
