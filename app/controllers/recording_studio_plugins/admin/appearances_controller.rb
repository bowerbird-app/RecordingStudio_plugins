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
        unless Appearance.configured?
          @unconfigured = true
          @rows = []
          return
        end

        assign_rows
      end

      def edit
        definition = plugin_definition
        unless definition
          head :not_found
          return
        end

        prepare_edit_recording!(definition)
        @row = appearance_row(definition)
      end

      def update
        authorize_plugin_staff!(role: :admin)
        definition = plugin_definition
        unless definition
          head :not_found
          return
        end

        save_name(definition.key)
        redirect_to admin_plugins_path, notice: plugin_copy("admin.flashes.saved")
      end

      def destroy_image
        authorize_plugin_staff!(role: :admin)
        Appearance.remove_image!(params[:key], actor: staff_actor)
        redirect_to admin_plugin_edit_path(params[:key]), notice: plugin_copy("admin.flashes.picture_removed")
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
        @rows = RecordingStudioPlugins.all.map { |definition| appearance_row(definition) }
      end

      def appearance_row(definition)
        key = definition.key
        recording = Appearance.recording_for(key)
        {
          definition:, key:, registered_name: definition.name, recording:,
          name: Appearance.display_name(definition), custom_name: recording&.recordable&.name,
          image_url: Appearance.image_url(definition), attachment_recording: Appearance.image_recording(key)
        }
      end

      def plugin_definition
        definition = RecordingStudioPlugins.find(params[:key])
        return if definition.nil? || RecordingStudioPlugins.configuration.hidden?(definition.key)

        definition
      end

      def prepare_edit_recording!(definition)
        return unless Appearance.configured?
        return unless staff_can_change_appearance?

        Appearance.ensure_recording!(definition.key, actor: staff_actor)
      end

      def staff_can_change_appearance?
        context = recording_studio_admin_context
        actor = context.current_actor
        recording = context.access_recording
        actor && recording && RecordingStudioAccessible.authorized?(actor:, recording:, role: :admin)
      end

      def save_name(key)
        attrs = appearance_params[key.to_s] || appearance_params[key.to_sym]
        Appearance.update_name!(key, name: attrs&.fetch(:name, nil), actor: staff_actor)
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
