class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true
  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)
  RecordingStudio.enable_capability(:attachable, on: self) if defined?(RecordingStudioAttachable)
end
