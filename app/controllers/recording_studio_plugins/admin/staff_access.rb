# frozen_string_literal: true

module RecordingStudioPlugins
  module Admin
    module StaffAccess
      extend ActiveSupport::Concern

      included do
        before_action :authorize_plugin_staff!
        rescue_from RecordingStudioAdmin::AuthorizationFailed, with: :render_staff_forbidden
        rescue_from RecordingStudioAdmin::DefinitionNotFound, with: :render_staff_forbidden
        helper_method :recording_studio_admin_context, :plugin_admin_back_href, :plugin_staff_admin?
      end

      private

      def authorize_plugin_staff!(role: :view)
        context = recording_studio_admin_context
        recording = plugin_admin_root_recording(context)
        deny_unless_admin_root_access!(context, recording)
        RecordingStudioAdmin::Authorization.authorize!(context, recording: recording, role: role)
        RecordingStudioAdmin::BlastRadius.authorize!(
          RecordingStudioPlugins::Admin::PluginsSection,
          context: context,
          recording: recording,
          label: "Plugins"
        )
      end

      def deny_unless_admin_root_access!(context, recording)
        return if recording.present? && same_recording?(context.access_recording, recording)

        raise RecordingStudioAdmin::AuthorizationFailed, helpers.plugin_copy("admin.forbidden.description")
      end

      def recording_studio_admin_context
        @recording_studio_admin_context ||= RecordingStudioAdmin::Context.new(
          params: params.to_unsafe_h,
          current_actor: staff_actor,
          controller: self,
          routes: main_app,
          view_context: view_context
        )
      end

      def plugin_staff_admin?
        return @plugin_staff_admin unless @plugin_staff_admin.nil?

        @plugin_staff_admin = staff_on_admin_root?(:admin)
      end

      def staff_on_admin_root?(role)
        context = recording_studio_admin_context
        recording = plugin_admin_root_recording(context)
        actor = context.current_actor
        return false unless actor && recording && same_recording?(context.access_recording, recording)
        return false unless admin_root_is_current?(context, recording)

        RecordingStudioAccessible.authorized?(actor:, recording:, role:)
      end

      def plugin_admin_root_recording(context)
        context.site_admin_recording.presence || Appearance.admin_recording
      end

      def admin_root_is_current?(context, recording)
        RecordingStudioAdmin::Authorization.ensure_current_root_matches!(context, recording)
        true
      rescue RecordingStudioAdmin::AuthorizationFailed
        false
      end

      def same_recording?(left, right)
        return false if left.blank? || right.blank?
        return true if left == right

        left.respond_to?(:id) && right.respond_to?(:id) && left.id.present? && left.id == right.id
      end

      def staff_actor
        if defined?(Current) && Current.respond_to?(:actor) && Current.actor
          Current.actor
        elsif respond_to?(:current_user)
          current_user
        end
      end

      def plugin_admin_back_href
        recording_studio_admin_context.admin_section_path("plugins")
      end

      def render_staff_forbidden
        render "recording_studio_plugins/plugins/forbidden", status: :forbidden
      end
    end
  end
end
