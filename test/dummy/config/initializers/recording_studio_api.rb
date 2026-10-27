# frozen_string_literal: true

RecordingStudioApi.configure do |config|
  # This dummy has no AdminRoot. Oauth still eager-loads AdminApi, which must
  # stay in recordable_types, but it is not parented under a staff root here.
  config.admin_root_recordable_type_names = []
  config.layout_name = "recording_studio/default_layout"
  config.admin_layout_name = "recording_studio/default_layout"
end
