# frozen_string_literal: true

module RecordingStudioPlugins
  class McpClientStatus
    def initialize(key)
      @key = key.to_sym
    end

    def self.connection_status(**)
      RecordingStudioOauth.inbound_connection_status(**)
    end

    def status(plugin_context)
      payload = self.class.connection_status(
        plugin_key: @key,
        root: plugin_context.root_recording,
        actor: plugin_context.actor
      )
      map_status(payload)
    end

    private

    def map_status(payload)
      count_text = people_connected_text(payload[:connected_count])
      if payload[:connected]
        Status.new(state: :connected, message: count_text)
      else
        Status.new(message: count_text)
      end
    end

    def people_connected_text(count)
      return if count.nil? || count.to_i <= 0

      copy("status.people_connected", count: count, default: fallback_people_connected(count))
    end

    def fallback_people_connected(count)
      return "1 person connected" if count == 1

      "#{count} people connected"
    end

    def copy(key, **)
      RecordingStudio.t("recording_studio.plugins.#{key}", **)
    end
  end
end
