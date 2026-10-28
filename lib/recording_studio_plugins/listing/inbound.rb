# frozen_string_literal: true

module RecordingStudioPlugins
  class Listing
    module Inbound
      def directory_status_text
        return if status_failed? || !user?
        return unless connected?

        copy("status.connected")
      end

      def people_connected_text
        return unless user?

        status_record&.message.presence
      end

      def setup_href
        SafeUrl.https_only(definition.setup_url)
      end

      def inbound_people
        return [] unless user?

        InboundPeople.labeled(plugin_key: key, plugin_context: plugin_context)
      end
    end
  end
end
