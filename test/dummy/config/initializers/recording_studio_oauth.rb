# frozen_string_literal: true

RecordingStudioOauth.configure do |config|
  config.authentication_method = :authenticate_user!
  config.current_actor_method = :current_user
  config.connectable_root_recordable_type_names = ["Workspace"]
  config.engine_mount_path = "/recording_studio_oauth"
end
