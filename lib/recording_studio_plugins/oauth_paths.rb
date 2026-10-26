# frozen_string_literal: true

require "erb"

module RecordingStudioPlugins
  module OauthPaths
    module_function

    def connect(provider:, root_recording_id:)
      query = "owner=root&root_recording_id=#{ERB::Util.url_encode(root_recording_id.to_s)}"
      "#{mount}/outbound/#{ERB::Util.url_encode(provider.to_s)}/connect?#{query}"
    end

    def disconnect(connection_id)
      "#{mount}/outbound/connections/#{ERB::Util.url_encode(connection_id.to_s)}"
    end

    def mount
      RecordingStudioOauth.configuration.engine_mount_path.to_s.chomp("/")
    end
  end
end
