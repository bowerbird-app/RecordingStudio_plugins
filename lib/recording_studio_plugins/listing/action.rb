# frozen_string_literal: true

module RecordingStudioPlugins
  class Listing
    module Action
      def action?(can_edit:)
        return false unless can_edit
        return false if status_failed?
        return false if connected? && action_href.blank?
        return false if rejected_action_url?

        true
      end

      def action_method
        return unless root?
        return :delete if connected?

        :post
      end

      def action_label
        status_record&.action_label.presence || copy("status.setup")
      end

      def action_href
        SafeUrl.allowed(status_record&.action_url)
      end

      def action_root_recording_id
        plugin_context.root_recording&.id
      end

      def action_external?
        SafeUrl.external?(action_href)
      end

      private

      def rejected_action_url?
        raw = status_record&.action_url
        raw.present? && action_href.nil?
      end
    end
  end
end
