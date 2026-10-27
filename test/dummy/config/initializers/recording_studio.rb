# frozen_string_literal: true

# Sibling engines in the dummy (such as Site Settings v0.2.0) still include
# RecordingStudio::UsesDefaultLayout until they upgrade to Recording Studio 6.1.
unless defined?(RecordingStudio::UsesDefaultLayout)
  module RecordingStudio
    module UsesDefaultLayout
      extend ActiveSupport::Concern

      included do
        layout(RecordingStudio::DEFAULT_LAYOUT)
        helper RecordingStudio::LayoutHelper
      end
    end
  end
end

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "RecordingStudioSiteSettings::SiteSetting",
    "RecordingStudioAttachable::Attachment",
    "RecordingStudioAttachable::Library",
    "RecordingStudioAttachable::Placement",
    "RecordingStudioApi::AdminApi"
  ]

  # Require each configured ActiveRecord type to call recording_studio_recordable.
  config.require_recordable_declarations = true

  # Shown in the shared default layout title fallback.
  config.app_name = "Plugins" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup
end
