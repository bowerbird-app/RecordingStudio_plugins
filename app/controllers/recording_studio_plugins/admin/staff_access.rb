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
        deny_unless_staff_role!(role)
        RecordingStudioAdmin::BlastRadius.authorize!(
          RecordingStudioPlugins::Admin::PluginsSection,
          context: recording_studio_admin_context,
          label: "Plugins"
        )
      end

      def deny_unless_staff_role!(role)
        context = recording_studio_admin_context
        actor = context.current_actor
        recording = context.access_recording
        return if actor && recording && RecordingStudioAccessible.authorized?(actor:, recording:, role:)

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

        context = recording_studio_admin_context
        actor = context.current_actor
        recording = context.access_recording
        @plugin_staff_admin = actor.present? && recording.present? &&
                              RecordingStudioAccessible.authorized?(actor:, recording:, role: :admin)
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
