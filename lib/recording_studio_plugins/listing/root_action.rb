# frozen_string_literal: true

module RecordingStudioPlugins
  class Listing
    module RootAction
      def action_method
        return unless root?
        return :delete if connected?

        :post
      end

      def action_root_recording_id
        plugin_context.root_recording&.id
      end
    end
  end
end
