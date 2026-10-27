# frozen_string_literal: true

module RecordingStudioPlugins
  module Admin
    class AppearancesController < ApplicationController
      helper RecordingStudioAttachable::ApplicationHelper
      helper Rails.application.routes.mounted_helpers
      helper_method :recording_direct_uploads_path

      before_action :authorize_plugin_staff!
      rescue_from RecordingStudioAdmin::AuthorizationFailed, with: :render_staff_forbidden
      rescue_from RecordingStudioAdmin::DefinitionNotFound, with: :render_staff_forbidden

      helper_method :recording_studio_admin_context, :plugin_admin_back_href

      def index
        assign_rows
      end

      def update
        authorize_plugin_staff!(role: :admin)
        save_names
        redirect_to admin_plugins_path, notice: plugin_copy("admin.flashes.saved")
      end

      def destroy_image
        authorize_plugin_staff!(role: :admin)
        Appearance.remove_image!(params[:key], actor: staff_actor)
        redirect_to admin_plugins_path, notice: plugin_copy("admin.flashes.picture_removed")
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

        raise RecordingStudioAdmin::AuthorizationFailed, plugin_copy("admin.forbidden.description")
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

      def staff_actor
        if defined?(Current) && Current.respond_to?(:actor) && Current.actor
          Current.actor
        elsif respond_to?(:current_user)
          current_user
        end
      end

      def assign_rows
        actor = staff_actor
        @rows = RecordingStudioPlugins.all.map { |definition| appearance_row(definition, actor) }
      end

      def appearance_row(definition, actor)
        recording = Appearance.ensure_recording!(definition.key, actor: actor)
        key = definition.key
        {
          definition:, key:, registered_name: definition.name, recording:,
          name: Appearance.display_name(definition), custom_name: recording&.recordable&.name,
          image_url: Appearance.image_url(definition), attachment_recording: Appearance.image_recording(key)
        }
      end

      def save_names
        appearance_params.each do |key, attrs|
          Appearance.update_name!(key, name: attrs[:name], actor: staff_actor)
        end
      end

      def appearance_params
        raw = params[:appearances]
        return {} if raw.blank?

        hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        hash.each_with_object({}) do |(key, attrs), allowed|
          next unless key.to_s.match?(/\A[a-z][a-z0-9_]*\z/)

          values = attrs.respond_to?(:to_h) ? attrs.to_h : {}
          allowed[key] = { name: values["name"] || values[:name] }
        end
      end

      def plugin_copy(key, default: nil)
        RecordingStudio.t("recording_studio.plugins.#{key}", default: default)
      end

      def plugin_admin_back_href
        recording_studio_admin_context.admin_section_path("plugins")
      rescue StandardError
        "/admin"
      end

      def render_staff_forbidden
        render "recording_studio_plugins/plugins/forbidden", status: :forbidden
      end

      def recording_direct_uploads_path(recording, **)
        recording_studio_attachable.recording_direct_uploads_path(recording, **)
      end
    end
  end
end
