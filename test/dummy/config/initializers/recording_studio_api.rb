# frozen_string_literal: true

RecordingStudioApi.configure do |config|
  config.admin_root_recordable_type_names = ["AdminRoot"]
  config.layout_name = "recording_studio/default_layout"
  config.admin_layout_name = "recording_studio/default_layout"
end
