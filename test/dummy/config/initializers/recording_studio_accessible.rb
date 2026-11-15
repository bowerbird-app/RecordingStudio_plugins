# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User", "RecordingStudioOauth::OauthAuthorization" ]

  # Site blast radius is allowed only on this recording. Admin uses the same root.
  config.admin_root_resolver = lambda do
    admin_root = AdminRoot.find_by(name: "Admin")
    next unless admin_root

    RecordingStudio::Recording.kept.find_by(recordable: admin_root)
  end
end
